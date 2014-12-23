require 'spec_helper'

RSpec.describe ArticlesController, :type => :controller do
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
      it 'creates new article (is_published: true)' do
        post :create, {"article" => {"title"=>"new article", "content"=>"<p>aaaa</p>", "is_published"=>"true"}}
        article = Article.last
        expect(article.title).to eq("new article")
        expect(article.is_published).to eq(true)
        expect(response).to redirect_to(attachments_path)
      end

      it 'creates new article (is_published: false)' do
        post :create, {"article" => {"title"=>"new article", "content"=>"<p>aaaa</p>", "is_published"=>"false"}}
        article = Article.last
        expect(article.title).to eq("new article")
        expect(article.is_published).to eq(false)
        expect(response).to redirect_to(attachments_path)
      end
    end

    it 'displays article' do
      article = FactoryGirl.create(:article)
      get :show, id: article.id
      expect(response).to be_success
    end

    it 'renders edit template' do
      article = FactoryGirl.create(:article)
      get :edit, id: article.id
      expect(response).to be_success
    end

    describe '#update' do
      before(:each) do
        @article = FactoryGirl.create(:article)
      end

      it 'make is_published false' do
        post :update, {id: @article.id, "article" => {"is_published" => false}}
        expect(@article.reload.is_published).to eq(false)
      end

      it 'make is_published true' do
        post :update, {id: @article.id, "article" => {"is_published" => true}}
        expect(@article.reload.is_published).to eq(true)
      end

      it 'redirects to attachments_path' do
        post :update, {id: @article.id, "article" => {"is_published" => true}}
        expect(response).to redirect_to(attachments_path)
      end
    end

    it 'destroys article' do
      @article = FactoryGirl.create(:article)
      post :destroy, {id: @article.id}
      expect(Article.count).to eq(0)
      expect(response).to redirect_to(attachments_path)
    end
  end
end
