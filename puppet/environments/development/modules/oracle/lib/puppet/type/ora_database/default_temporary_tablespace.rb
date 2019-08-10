# encoding: UTF-8
require 'ora_utils/schemas'
require 'utils/hash'

newparam(:default_temporary_tablespace) do
  class ::Puppet::Type::Ora_database::ParameterDefault_temporary_tablespace
    include EasyType
    include OraUtils::Schemas
    include Utils::Hash

    desc <<-EOD 
    Specify the default temporary tablespace. 

    Use this syntax to specify all attributes:

      ora_database{'dbname':
        ...
        default_temporary_tablespace => {
          name      => 'TEMP',
          tempfile  => {
            file_name  => 'tmp.dbs',
            size       => '10G',
            reuse      =>  true,
          }
          extent_management => {
            type          => 'local',
            autoallocate  => true,
            uniform_size  => '5G',
          }
        }
      }

    EOD

    TEMPFILE          = OraUtils::Schemas::DATAFILE
    EXTENT_MANAGEMENT = OraUtils::Schemas::EXTENT_MANAGEMENT
    TABLESPACE_TYPE   = OraUtils::Schemas::TABLESPACE_TYPE

    VALIDATION = {
      'name'               => String,
      'type'               => [:optional, TABLESPACE_TYPE],
      'tempfile'           => [:optional, DATAFILE],
      'extent_management'  => [:optional, EXTENT_MANAGEMENT]
    }

    def validate(value)
      ClassyHash.validate_strict(value, VALIDATION)
      use_hash(value)
      validate_extent_management(value_for('extent_management'))
    end
    

    def value
      use_hash(@value)
      command_segment = "#{value_for('type')} default temporary tablespace #{value_for('name')}"
      command_segment << " datafile #{datafiles(datafile_data)}" if exists?('datafile')
      command_segment << " #{extent_management(value_for('extent_management'))}" if exists?('extent_management')
    end
  end
  
end
