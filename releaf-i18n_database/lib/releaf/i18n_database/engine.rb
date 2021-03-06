module Releaf::I18nDatabase
  mattr_accessor :create_missing_translations
  @@create_missing_translations = true

  class Engine < ::Rails::Engine
  end

  def self.components
    [Releaf::I18nDatabase::HumanizeMissingTranslations]
  end

  def self.initialize_component
    I18n.backend = Releaf::I18nDatabase::Backend.new
  end

  def self.draw_component_routes router
    router.namespace :i18n_database, path: nil do
      router.resources :translations, only: [:index] do
        router.collection do
          router.get :edit
          router.post :update
          router.get :export
          router.post :import
        end
      end
    end
  end
end
