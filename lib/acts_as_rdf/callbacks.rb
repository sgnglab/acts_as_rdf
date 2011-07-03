# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module Callbacks
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Callbacks
        include ActiveModel::Validations::Callbacks

        define_model_callbacks :create, :save #, :destroy, :save, :update
      end
    end
  end
end
