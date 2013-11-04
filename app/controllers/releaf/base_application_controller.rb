module Releaf
  class BaseApplicationController < ActionController::Base
    before_filter :manage_ajax
    before_filter "authenticate_#{ReleafDeviseHelper.devise_admin_model_name}!"
    before_filter :set_locale

    rescue_from Releaf::AccessDenied, with: :access_denied
    rescue_from Releaf::FeatureDisabled, with: :feature_disabled

    layout :layout
    protect_from_forgery

    helper_method \
      :controller_scope_name,
      :ajax?,
      :current_params

    # return contoller translation scope name for using
    # with I18.translation call within hash params
    # ex. t("save", scope: controller_scope_name)
    def controller_scope_name
      'admin.' + self.class.name.sub(/Controller$/, '').underscore.gsub('/', '_')
    end

    # returns all params except :controller, :action and :format
    def current_params
      params.except(:controller, :action, :format)
    end

    # set locale for interface translating from current admin user
    def set_locale
      admin = send("current_" + ReleafDeviseHelper.devise_admin_model_name)
      I18n.locale = admin.locale
      Releaf::Globalize3::Fallbacks.set
    end

    def feature_disabled exception
      @feature = exception.message
      error_response('feature_disabled', 403)
    end

    def access_denied
      error_response('access_denied', 403)
    end

    def page_not_found
      error_response('page_not_found', 404)
    end

    def ajax?
      @_ajax || false
    end

    def layout
      ajax? ? false : Releaf.layout
    end

    private

    def manage_ajax
      @_ajax = params.has_key? :ajax
      params.delete(:ajax)
    end

    def error_response error_page, error_status
      respond_to do |format|
        format.html { render "releaf/error_pages/#{error_page}", status: error_status }
        format.any  { render text: '', status: error_status }
      end
    end

  end
end
