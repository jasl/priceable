require "priceable/version"
require "bigdecimal"

module Priceable
  SUFFIXES = ["_in_cents", "_in_pennies", "_as_integer"]
  def priceable(*price_fields)
    price_fields.each do |price_field|
      suffix = SUFFIXES.detect { |suffix| self.attribute_method? "#{price_field}#{suffix}".to_sym }
      raise ArgumentError, "Unable to find valid database field for `#{price_field}'" unless suffix

      define_method price_field do
        if send(:"#{price_field}#{suffix}")
          BigDecimal(send(:"#{price_field}#{suffix}")) / 100
        else
          BigDecimal.new(0)
        end
      end

      define_method :"#{price_field}=" do |new_price|
        send(:"#{price_field}#{suffix}=", (BigDecimal(new_price) * 100).to_i)
      end
    end

    unless Rails::VERSION::MAJOR == 4 && !defined?(ProtectedAttributes)
      if self._accessible_attributes?
        attr_accessible *price_fields
      end
    end
  end
end

ActiveRecord::Base.send(:extend, Priceable) if defined?(ActiveRecord)
