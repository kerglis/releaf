module Helpers
  def auth_as_admin full_login = false, factory = :admin
    if factory.is_a? Releaf::Admin
      admin = factory
    else
      admin = FactoryGirl.create(factory)
    end
    if full_login
      visit "/"
      within("form.login") do
        fill_in 'Email',    :with => admin.email
        fill_in 'Password', :with => admin.password
      end

      click_button 'Sign in'
    else
      login_as admin
    end

    return admin
  end

  def save_and_check_response status_text
    click_button 'Save'
    expect(page).to have_css('body > .notifications .notification[data-id="resource_status"][data-type="success"]', text: status_text)
  end

  def open_toolbox_dialog item_name, resource = nil
    open_toolbox(item_name, resource)
    expect(page).to have_css('.dialog form[data-validation="true"][data-validation-initialized="true"]')
  end

  def open_toolbox item_name, resource = nil
    if resource
      find('.view-index .table tr[data-id="' + resource.id.to_s  + '"] .toolbox button.trigger').click
    else
      find('.main h2.header .toolbox-wrap .toolbox button.trigger').click
    end

    click_link item_name
  end
end
