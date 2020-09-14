require 'spec_helper'

describe LeaveApplication do
  context 'Validation specs' do
    it { should have_fields(:start_at, :end_at, :reason, :contact_number,
                                             :reject_reason, :leave_status) }
    it { should belong_to(:user) }
    it { should validate_presence_of(:start_at) }
    it { should validate_presence_of(:end_at) }
    it { should validate_presence_of(:reason) }
    it { should validate_presence_of(:contact_number) }
    it { should validate_numericality_of(:contact_number) }
    it { should validate_presence_of(:leave_type) }
    it { is_expected.to validate_inclusion_of(:leave_type).to_allow(LeaveApplication::LEAVE_TYPES) }
  end

  context 'Validate date - Cross date validation - ' do

    before do
      @user = FactoryGirl.create(:user)
    end

    it 'should not be able to apply leave for same date' do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      leave_application2 = FactoryGirl.build(:leave_application, user: @user)
      expect(leave_application2.valid?).to eq(false)
      expect(leave_application2.errors[:base]).
        to eq(["Already applied for LEAVE/WFH on same date"])
    end

    it 'start date should not exists in the range of applied leaves' do
      FactoryGirl.create(:leave_application, start_at: Date.today, end_at: Date.today + 2, user: @user)
      leave_application = FactoryGirl.build(:leave_application, start_at: Date.today + 1, end_at: Date.today + 3, user: @user)
      leave_application.save
      expect(leave_application.errors[:base]).to eq(["Already applied for LEAVE/WFH on same date"])
    end

    it 'end date should not exists in the range of applied leaves' do
      FactoryGirl.create(:leave_application, start_at: Date.today, end_at: Date.today + 2, user: @user)
      leave_application = FactoryGirl.build(:leave_application, start_at: Date.today - 1, end_at: Date.today + 1, user: @user)
      leave_application.save
      expect(leave_application.errors[:base]).to eq(["Already applied for LEAVE/WFH on same date"])
    end

    it 'start date of future leave should not clash with that of existing leave' do
      FactoryGirl.create(:leave_application, start_at: Date.today, end_at: Date.today + 2, user: @user)
      FactoryGirl.create(:leave_application, start_at: Date.today - 3, end_at: Date.today - 1, user: @user)
      leave_application = FactoryGirl.build(:leave_application, start_at: Date.today + 1, end_at: Date.today + 3, user: @user)
      leave_application.save
      expect(leave_application.errors[:base]).to eq(["Already applied for LEAVE/WFH on same date"])
    end

    it 'end date of future leave should not clash with that of existing leave' do
      FactoryGirl.create(:leave_application, start_at: Date.today, end_at: Date.today + 2, user: @user)
      FactoryGirl.create(:leave_application, start_at: Date.today - 3, end_at: Date.today - 1, user: @user)
      leave_application = FactoryGirl.build(:leave_application, start_at: Date.today - 6, end_at: Date.today - 1, user: @user)
      leave_application.save
      expect(leave_application.errors[:base]).to eq(["Already applied for LEAVE/WFH on same date"])
    end

  end

  context 'Method specs ' do

    before do
      @user = FactoryGirl.create(:user)
      @user = FactoryGirl.create(:user)
    end

    it 'end date can be equal to start date' do
      leave_application = FactoryGirl.build(:leave_application, user: @user)
      leave_application.start_at = Date.today
      leave_application.end_at = Date.today
      expect(leave_application.valid?).to eq(true)
    end

    it 'end date should not be less than start date' do
      date = Date.today
      leave_application = FactoryGirl.build(:leave_application, user: @user)
      leave_application.start_at = date
      leave_application.end_at = (date - 1.day)
      expect(leave_application.valid?).to eq(false)
      expect(leave_application.errors[:end_at]).to be_present
    end

    it "mail for approval shouldn't get sent if not pending" do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      leave_application.update_attributes(leave_status: 'Approved')
      expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(0)
    end

    it "approval mail should be sent if a field has been updated & pending" do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      leave_application.update_attributes(number_of_days: 1)
      expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
    end

    context 'self.process_leave ' do

      before do
        @user = FactoryGirl.create(:user)
        @user = FactoryGirl.create(:user)
        @available_leaves = @user.employee_detail.available_leaves
        @number_of_days = HolidayList.number_of_working_days(Date.today + 2, Date.today + 3)
      end

      it 'should add leaves back if status changed from approved to rejected' do
        leave_application = FactoryGirl.create(:leave_application, user: @user)
        @user.reload
        expect(@user.employee_detail.available_leaves).
          to eq(@available_leaves - @number_of_days)
        @message = LeaveApplication.process_leave(
          leave_application.id,
          APPROVED,
          :process_accept_application,
          ''
        )
        @user.reload
        expect(@user.employee_detail.available_leaves).
          to eq(@available_leaves - @number_of_days)

        expect(@message).to eq({type: :notice, text: "Approved Successfully"})

        @message = LeaveApplication.process_leave(
          leave_application.id,
          REJECTED,
          :process_reject_application,
          ''
        )
        expect(@message).to eq({type: :notice, text: "Rejected Successfully"})
        @user.reload
        expect(@user.employee_detail.available_leaves).to eq(@available_leaves)
      end

      context 'should deduct leaves if status changed from' do
        it 'nil to pending' do
          leave_application = FactoryGirl.create(:leave_application,
            user: @user
          )
          @user.reload
          expect(@user.employee_detail.available_leaves).
            to eq(@available_leaves - @number_of_days)
        end

        it 'rejected to approved' do
          leave_application = FactoryGirl.create(:leave_application,
            user: @user
          )
          @user.reload
          expect(@user.employee_detail.available_leaves).
            to eq(@available_leaves - @number_of_days)

          @message = LeaveApplication.process_leave(
            leave_application.id,
            REJECTED,
            :process_reject_application,
            ''
          )
          expect(@message).to eq(
            {type: :notice, text: "Rejected Successfully"}
          )
          @user.reload
          expect(@user.employee_detail.available_leaves).
            to eq(@available_leaves)

          @message = LeaveApplication.process_leave(
            leave_application.id,
            APPROVED,
            :process_accept_application,
            ''
          )
          @user.reload
          expect(@user.employee_detail.available_leaves).
            to eq(@available_leaves - @number_of_days)

          expect(@message).to eq(
            {type: :notice, text: "Approved Successfully"}
          )
        end
      end

      context 'should not deduct leaves if status ' do

        it 'changed from pending to approved' do
          leave_application = FactoryGirl.create(:leave_application,
            user: @user
          )
          @user.reload
          available_leaves = @user.employee_detail.available_leaves

          @message = LeaveApplication.process_leave(
            leave_application.id,
            APPROVED,
            :process_accept_application,
            ''
          )
          @user.reload
          expect(@user.employee_detail.available_leaves).to eq(available_leaves)

          expect(@message).to eq({type: :notice, text: "Approved Successfully"})
        end

        it 'does not change' do
          leave_application = FactoryGirl.create(:leave_application,
            user: @user
          )
          LeaveApplication.process_leave(
            leave_application.id,
            APPROVED,
            :process_accept_application,
            ''
          )
          @user.reload
          available_leaves = @user.employee_detail.available_leaves

          @message = LeaveApplication.process_leave(
            leave_application.id,
            APPROVED,
            :process_accept_application,
            ''
          )
          @user.reload
          expect(@user.employee_detail.available_leaves).to eq(available_leaves)

          expect(@message).
            to eq({type: :error, text: "#{leave_application.leave_type} is already Approved"})
        end
      end

      context 'Deduction of leaves' do
        it 'should deduct leaves of going year only' do
          start_at = Date.today.end_of_year - 5
          end_at = Date.today.end_of_year + 2
          number_of_days = HolidayList.number_of_working_days(start_at, end_at)
          previous_available_leaves = @user.employee_detail.available_leaves

          number_of_days_to_be_deducted = HolidayList.number_of_working_days(start_at, start_at.end_of_year)

          leave_application = FactoryGirl.create(:leave_application,
            user: @user,
            start_at: start_at,
            end_at: end_at,
            number_of_days: number_of_days
          )
          @user.reload
          available_leaves = @user.employee_detail.available_leaves
          expect(available_leaves).to eq(previous_available_leaves - number_of_days_to_be_deducted)
        end

        it 'should not deduct leaves for next year' do
          start_at = Date.today.end_of_year + 2
          end_at = Date.today.end_of_year + 6
          number_of_days = HolidayList.number_of_working_days(start_at, end_at)
          previous_available_leaves = @user.employee_detail.available_leaves

          leave_application = FactoryGirl.create(:leave_application,
            user: @user,
            start_at: start_at,
            end_at: end_at,
            number_of_days: number_of_days
          )
          @user.reload
          available_leaves = @user.employee_detail.available_leaves
          expect(available_leaves).to eq(previous_available_leaves)
        end
      end

      context 'Leave reminder mail' do
        let!(:user) { FactoryGirl.create(:employee) }
        let!(:project) { FactoryGirl.create(:project, manager_ids: [user.id])}
        let!(:user_project) { FactoryGirl.create(:user_project, user: user, project: project
        )}
        before do
          ActionMailer::Base.deliveries = []
        end
        it 'send reminder mail if leave begins in next 2 day' do
          leave_application = FactoryGirl.create(:leave_application, user: user)
          LeaveApplication.pending_leaves_reminder
          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end

        it 'send reminder mail if leave begins in next 1 day' do
          leave_application = FactoryGirl.create(:leave_application,
            user: user,
            start_at: Date.today + 1,
            end_at: Date.today + 1,
          )
          LeaveApplication.pending_leaves_reminder
          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end

        it 'should not send mail if leave application is empty' do
          LeaveApplication.pending_leaves_reminder
          expect(ActionMailer::Base.deliveries.count).to eq(0)
        end
      end
    end

    context 'Class methods' do
      before do
        @user = FactoryGirl.create(:user)
        #Past leave
        FactoryGirl.create(:leave_application, start_at: Date.today - 2.months, end_at: Date.today - 2.months, number_of_days: 1, leave_status: PENDING, user: @user)
        FactoryGirl.create(:leave_application, start_at: Date.today - 2.months - 1, end_at: Date.today - 2.months - 1, number_of_days: 1, leave_status: APPROVED, user: @user)
        FactoryGirl.create(:leave_application, start_at: Date.today - 6.months - 1, end_at: Date.today - 6.months - 1, number_of_days: 1, leave_status: APPROVED, user: @user)
        FactoryGirl.create(:leave_application, start_at: Date.today - 2.months - 2, end_at: Date.today - 2.months - 2, number_of_days: 1, leave_status: REJECTED, user: @user)
        #Upcoming leave
        FactoryGirl.create(:leave_application, start_at: Date.today + 2.months, end_at: Date.today + 2.months, number_of_days: 1, leave_status: PENDING, user: @user)
        FactoryGirl.create(:leave_application, start_at: Date.today + 2.months + 1, end_at: Date.today + 2.months + 1, number_of_days: 1, leave_status: APPROVED, user: @user)
        FactoryGirl.create(:leave_application, start_at: Date.today + 6.months + 1, end_at: Date.today + 6.months + 1, number_of_days: 1, leave_status: APPROVED, user: @user)
        FactoryGirl.create(:leave_application, start_at: Date.today + 2.months + 2, end_at: Date.today + 2.months + 2, number_of_days: 1, leave_status: REJECTED, user: @user)
      end

      context 'self.get_users_past_leaves' do
        it 'should give past 6 month approved leaves only' do
          past_leaves = LeaveApplication.get_users_past_leaves(@user.id)
          expect(past_leaves.count).to eq(1)
        end
      end

      context 'self.get_users_upcoming_leaves' do
        it 'should give upcoming unrejected leaves only' do
          past_leaves = LeaveApplication.get_users_upcoming_leaves(@user.id)
          expect(past_leaves.count).to eq(3)
        end
      end
    end
  end

  describe '#deduct_available_leave_send_mail' do
    let!(:user) { create(:user) }

    context 'when request is for LEAVE' do
      it 'deduct leave from available leave' do
        employee_detail = user.employee_detail
        available_leaves = employee_detail.available_leaves
        leave_application = create(:leave_application, user: user, number_of_days: 2)
        expect(employee_detail.available_leaves).to eq(available_leaves - 2)
      end
    end

    context 'when request is for WFH' do
      it 'should not deduct leave from available leave' do
        employee_detail = user.employee_detail
        available_leaves = employee_detail.available_leaves
        leave_application = create(:leave_application, user: user, number_of_days: 1, leave_type: LeaveApplication::WFH)
        expect(employee_detail.available_leaves).to eq(available_leaves)
      end
    end
  end

  describe '#update_available_leave_send_mail' do
    let!(:user) { create(:user) }

    context 'when request is for LEAVE' do
      it 'should update available leaves with new leaves changes' do
        employee_detail = user.employee_detail
        available_leaves = employee_detail.available_leaves
        leave_application = create(:leave_application, user: user, number_of_days: 1, leave_type: LeaveApplication::LEAVE)
        leave_application.number_of_days = 2
        leave_application.save
        expect(employee_detail.available_leaves).to eq(available_leaves - leave_application.number_of_days)
      end

      it 'should update available leaves when leave type changed from LEAVE to WFH' do
        employee_detail = user.employee_detail
        available_leaves = employee_detail.available_leaves
        leave_application = create(:leave_application, user: user, number_of_days: 2, leave_type: LeaveApplication::LEAVE)
        expect(employee_detail.reload.available_leaves).to eq(available_leaves - leave_application.number_of_days)
        leave_application.leave_type = LeaveApplication::WFH
        leave_application.save
        expect(employee_detail.reload.available_leaves).to eq(available_leaves)
      end

      it 'should update available leaves when leave type changed from WFH to LEAVE' do
        employee_detail = user.employee_detail
        available_leaves = employee_detail.available_leaves
        leave_application = create(:leave_application, user: user, number_of_days: 2, leave_type: LeaveApplication::WFH)
        expect(employee_detail.reload.available_leaves).to eq(available_leaves)
        leave_application.leave_type = LeaveApplication::LEAVE
        leave_application.save
        expect(employee_detail.reload.available_leaves).to eq(available_leaves - leave_application.number_of_days)
      end
    end
  end

  describe '#process_reject_application' do
    let!(:user) { create(:user) }

    context 'when request is for LEAVE' do
      it 'rejected leave should be added to available leaves' do
        employee_detail = user.employee_detail
        available_leaves = employee_detail.available_leaves
        leave_application = create(:leave_application, user: user, number_of_days: 2, leave_type: LeaveApplication::LEAVE)
        expect(employee_detail.available_leaves).to eq(available_leaves - leave_application.number_of_days)
        leave_application.process_reject_application
        expect(employee_detail.available_leaves).to eq(available_leaves)
      end
    end

    context 'when request is for WFH' do
      it 'rejected leave should not be added to available leaves' do
        employee_detail = user.employee_detail
        available_leaves = employee_detail.available_leaves
        wfh_application = create(:leave_application, user: user, number_of_days: 2, leave_type: LeaveApplication::WFH)
        expect(employee_detail.available_leaves).to eq(available_leaves)
        wfh_application.process_reject_application
        expect(employee_detail.available_leaves).to eq(available_leaves)
      end
    end
  end
end
