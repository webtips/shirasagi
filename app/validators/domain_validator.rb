class DomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    values = value.is_a?(Array) ? value : [values]
    values.each do |val|
      next if val.blank?
      next if /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(:\d{1,5})?$/ix.match?(val)
      #next if val =~ /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}(:[0-9]{1,5})?$/ix
      next if /^([\w\-]+\.)*[\w\-]+(:[0-9]{1,5})?$/ix.match?(val)
      record.errors.add(attribute, options[:message] || :domain)
      break
    end
  end
end
