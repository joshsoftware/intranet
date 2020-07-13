require 'rails_helper'

RSpec.describe EntryPassesController, type: :controller do
  before(:each) do
    @admin = FactoryGirl.create(:admin)
    sign_in @admin
  end

  describe "#index" do
    it 'renders index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe '#create' do
    context 'create passes' do
      it 'should send mail on new entry pass' do
        user = FactoryGirl.create(:user)
        sign_out @admin
        sign_in user
        entry_pass = FactoryGirl.attributes_for(:entry_pass, user: user)
        Sidekiq::Extensions::DelayedMailer.jobs.clear
        post :create, { user: { entry_passes_attributes: {
            '0' => entry_pass
          }}, format: :js }
        expect(flash[:success]).to eq("Entry Pass Created Successfully")
        expect(user.entry_passes.count).to eq(1)
        expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
      end

      it 'should not send mail if no new dates in entry passes' do
        user = FactoryGirl.create(:user)
        sign_out @admin
        sign_in user
        entry_pass1 = FactoryGirl.create(:entry_pass, user: user, date: Date.today)
        entry_pass2 = FactoryGirl.create(:entry_pass, user: user, date: Date.today + 1)
        Sidekiq::Extensions::DelayedMailer.jobs.clear
        entry_pass2.attributes['_destroy'] = '1'
        post :create, { user: { "entry_passes_attributes" => {
                '0' => entry_pass1.attributes,
                '1' => entry_pass2.attributes
            }}, format: :js}
        user.reload
        expect(flash[:success]).to eq("Entry Pass Created Successfully")
        expect(user.entry_passes.count).to eq(1)
        expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(0)
      end

      it 'should send mail if new dates present in entry passes' do
        user = FactoryGirl.create(:user)
        sign_out @admin
        sign_in user
        entry_pass1 = FactoryGirl.create(:entry_pass, user: user, date: Date.today)
        entry_pass2 = FactoryGirl.create(:entry_pass, user: user, date: Date.today + 1)
        entry_pass3 = FactoryGirl.attributes_for(:entry_pass, user: user, date: Date.today + 2)
        Sidekiq::Extensions::DelayedMailer.jobs.clear
        params =  { user:
                    { "entry_passes_attributes" => {
                      '0' => entry_pass1.attributes,
                      '1' => entry_pass2.attributes,
                      '2' => entry_pass3
                    }
                  }, format: :js}
        post :create, params
        expect(flash[:success]).to eq("Entry Pass Created Successfully")
        expect(user.entry_passes.count).to eq(3)
        expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
      end
    end

    context 'fail creating pass' do
      it 'should not create pass if details is absent' do
        user = FactoryGirl.create(:user)
        sign_out @admin
        sign_in user
        entry_pass = FactoryGirl.attributes_for(:entry_pass, user: user)
        Sidekiq::Extensions::DelayedMailer.jobs.clear
        post :create, { user: { entry_passes_attributes: {
            '0' => { date: Date.today }
          }}, format: :js }
        expect(flash[:error]).to eq("Error while creating entry passes, please try again.")
        expect(user.entry_passes.count).to eq(0)
        expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(0)
      end

      it 'should not create pass if date is absent' do
        user = FactoryGirl.create(:user)
        sign_out @admin
        sign_in user
        entry_pass = FactoryGirl.attributes_for(:entry_pass, user: user)
        Sidekiq::Extensions::DelayedMailer.jobs.clear
        post :create, { user: { entry_passes_attributes: {
            '0' => { details: "Deployment near. 10 - 5" }
          }}, format: :js }
        expect(flash[:error]).to eq("Error while creating entry passes, please try again.")
        expect(user.entry_passes.count).to eq(0)
        expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(0)
      end

      it 'should not create pass if date is already present' do
        user = FactoryGirl.create(:user)
        sign_out @admin
        sign_in user
        entry_pass = FactoryGirl.create(:entry_pass, user: user)
        Sidekiq::Extensions::DelayedMailer.jobs.clear
        post :create, { user: { entry_passes_attributes: {
            '0' => entry_pass.attributes,
            '1' => { date: Date.today, details: "Deployment near. 10 - 5" }
          }}, format: :js }
        expect(flash[:error]).to eq("Error while creating entry passes, please try again.")
        expect(user.entry_passes.count).to eq(1)
        expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(0)
      end
    end
  end

  describe '#destroy' do
    context 'delete entry passes' do
      it 'should not send mail if user deletes own entry pass' do
        user = FactoryGirl.create(:user)
        sign_out @admin
        sign_in user
        entry_pass1 = FactoryGirl.create(:entry_pass, user: user)
        Sidekiq::Extensions::DelayedMailer.jobs.clear
        delete :destroy, id: entry_pass1.id
        expect(flash[:success]).to eq("Entry Pass deleted successfully")
        expect(user.entry_passes.count).to eq(0)
        expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(0)
      end

      it "should send mail if admin deletes users' entry pass(es)" do
        user = FactoryGirl.create(:user)
        entry_pass1 = FactoryGirl.create(:entry_pass, user: user)
        Sidekiq::Extensions::DelayedMailer.jobs.clear
        delete :destroy, id: entry_pass1.id
        expect(flash[:success]).to eq("Entry Pass deleted successfully")
        expect(user.entry_passes.count).to eq(0)
        expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
      end
    end
  end

  describe "#report" do
    context "get report" do
      it "should return valid csv report for given date" do
        users = FactoryGirl.create_list(:user, 3)
        entry_pass1 = FactoryGirl.create(:entry_pass, user: users[0])
        entry_pass2 = FactoryGirl.create(:entry_pass, user: users[1])
        entry_pass3 = FactoryGirl.create(:entry_pass, user: users[2])
        entry_pass4 = FactoryGirl.create(:entry_pass, user: users[0], date: Date.tomorrow)
        entry_pass5 = FactoryGirl.create(:entry_pass, user: users[1], date: Date.today + 2)

        get :report, { date: Date.today, format: :csv }
        csv = response.body
        expected_csv =  "Date,Name,EmployeeID,Email\n" +
                        "#{entry_pass1.date},#{entry_pass1.user.name},#{entry_pass1.user.try(:employee_id)},#{entry_pass1.user.try(:email)}\n" +
                        "#{entry_pass2.date},#{entry_pass2.user.name},#{entry_pass2.user.try(:employee_id)},#{entry_pass2.user.try(:email)}\n" +
                        "#{entry_pass3.date},#{entry_pass3.user.name},#{entry_pass3.user.try(:employee_id)},#{entry_pass3.user.try(:email)}\n"
        expect(response).to have_http_status(200)
        expect(csv).to eq(expected_csv)
      end
    end
  end
end
