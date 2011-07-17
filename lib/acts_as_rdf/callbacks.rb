# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module Callbacks
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Callbacks
        include ActiveModel::Validations::Callbacks

        define_model_callbacks :create, :save, :update, :initialize #, :destroy
      end
    end
  end
end
