require 'spec_helper'

RSpec.describe PoliciesController, :type => :controller do
  context "As an Admin" do
    before(:each) do
      @admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin')
      sign_in @admin
    end

    it 'renders new template' do
      get :new
      expect(response).to render_template(:new)
    end

    describe '#create' do
      it 'creates new policy (is_published: true)' do
        post :create, {"policy" => {"title"=>"new article", "content"=>"<p>aaaa</p>", "is_published"=>"true"}}
        policy = Policy.last
        expect(policy.title).to eq("new article")
        expect(policy.is_published).to eq(true)
        expect(response).to redirect_to(attachments_path)
      end

      it 'creates new policy (is_published: false)' do
        post :create, {"policy" => {"title"=>"new article", "content"=>"<p>aaaa</p>", "is_published"=>"false"}}
        policy = Policy.last
        expect(policy.title).to eq("new article")
        expect(policy.is_published).to eq(false)
        expect(response).to redirect_to(attachments_path)
      end
    end

    it 'displays policy' do
      policy = FactoryGirl.create(:policy)
      get :show, id: policy.id
      expect(response).to be_success
    end

    it 'renders edit template' do
      policy = FactoryGirl.create(:policy)
      get :edit, id: policy.id
      expect(response).to be_success
    end

    describe '#update' do
      before(:each) do
        @policy = FactoryGirl.create(:policy)
      end

      it 'make is_published false' do
        post :update, {id: @policy.id, "policy" => {"is_published" => false}}
        expect(@policy.reload.is_published).to eq(false)
      end

      it 'make is_published true' do
        post :update, {id: @policy.id, "policy" => {"is_published" => true}}
        expect(@policy.reload.is_published).to eq(true)
      end

      it 'redirects to attachments_path' do
        post :update, {id: @policy.id, "policy" => {"is_published" => true}}
        expect(response).to redirect_to(attachments_path)
      end
    end

    it 'destroys policy' do
      @policy = FactoryGirl.create(:policy)
      post :destroy, {id: @policy.id}
      expect(Policy.count).to eq(0)
      expect(response).to redirect_to(attachments_path)
    end
  end
end
