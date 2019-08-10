require 'pathname'
require 'utils/classy_hash'

module OraUtils
  module Schemas
    BOOLEAN   = [TrueClass, 'Yes', 'No', 'Y', 'N', 'y', 'n']
    SIZE      = lambda do |v| 
      unless v =~ /^\d+\s?[K|k|M|m|G|g|T|t|P|p|E|e]?$/
        return "valid size value"
      else
        true 
      end
    end

    DATAFILE  = {
      'file_name' => [:optional, String],
      'reuse'     => [:optional, BOOLEAN],
      'size'      => [:optional, SIZE]
    }

    EXTENT_MANAGEMENT = {
      'type'         => lambda {|v|['local', 'dictionary'].include?(v.downcase) || 'local or dictonary'},
      'autoallocate' => [:optional, BOOLEAN],
      'uniform_size' => [:optional, SIZE]
    }

    TABLESPACE_TYPE = lambda {|v|['bigfile', 'smallfile'].include?(v.downcase) || 'bigfile or smallfile'}


    def validate_extent_management(value)
      if value
        with_hash(value) do
          type = value_for('type')
          if type.downcase == 'dictionary' && exists?('autoallocate')
            raise ArgumentError, 'extent management dictionary, incompatible with autoallocate'
          end
          if type.downcase == 'dictionary' && exists?('uniform_size')
            raise ArgumentError, 'extent management dictionary, incompatible with uniform_size'
          end
        end
      end
    end

    def datafiles(value)
      value = [value] unless value.is_a?(Array)  # values can be either a Hash or an Array
      value.collect do | v |
        entry = ''
        with_hash(v) do
          entry << "'#{value_for('file_name')}'"
          entry << content_if('size').to_s
          entry << key_if('reuse').to_s
        end
        entry
      end.join(', ')
    end

    def extent_management(value)
      return_value = ""
      with_hash(value) do
        return_value << "extent management #{value_for('type')}"
        return_value << key_if('autoallocate').to_s
        return_value << content_if('uniform_size').to_s
      end
      return_value
    end
  end
end