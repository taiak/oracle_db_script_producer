class ODSP
    require 'oci8'

    def initialize(
            save_config: {
                make: { folder: 'make', op_file: 'make_all.sql'},
                drop: { folder: 'drop', op_file: 'drop_all.sql'}
            },
            connections: { dest: nil, src: nil},
            params:      nil,
            debug_opt:   { time: true, console: true, commit: false, comment: true }
        )
        raise "Connections can not be defined as nil!" if connections.any? { |c| !c }
        @connections = connections

        @save_config = save_config
        @params = params || default_params
        @params.all? { |hsh| check_param_hsh(hsh) }
        @debug_opt = debug_opt
    end

    def produce
        @save_config.each do |op_name, config|
            raise "#{op_name} op_file or folder name can not be nil!" unless config[:op_file] || config[:folder]

            Dir.mkdir(config[:folder]) unless Dir.exist?(config[:folder])
            File.open(config[:op_file], 'w') { |f| f.write("-- script cleaned at #{Time.new}\n") if @debug_opt[:comment] }    
        end

        @params.each { |params| process_hsh(params) }
        true
    end

    private
    def check_param_hsh(hsh)
        raise 'hsh can not be false or nil!' unless hsh
        raise 'op_type can not be nil!' unless hsh[:op_type]
        raise 'Invalid op_type configuration in save_options!' unless @save_config[hsh[:op_type]]
        raise "Invalid folder name in save_options[#{hsh[:op_type]}]!" unless @save_config[hsh[:op_type]][:folder]
        raise "Invalid op_file name in save_options[#{hsh[:op_type]}]!" unless @save_config[hsh[:op_type]][:op_file]
        raise 'Parameter type can not be nil!' unless hsh[:type]
        raise 'Query can not be nil!' unless hsh[:query]
        raise 'Lambda operation can not be nil!' unless hsh[:lambda]
        raise 'Connection type can not be nil!' unless @connections[hsh[:connection]]
        true
    end

    def process_hsh(hsh)
        start = Time.new
        file_name = @save_config[hsh[:op_type]][:folder] + '/' + hsh[:type] + '.sql'

        File.open(file_name, 'w') do |f|
            p "running => #{hsh[:query]}" if @debug_opt[:console]
            f.write("-- #{hsh[:type]} script produced at #{Time.new}.\n") if @debug_opt[:comment]
            @connections[hsh[:connection]].exec(hsh[:query]) { |record| f.write(hsh[:lambda].call(record)) }
            f.write("COMMIT;") if @debug_opt[:commit]
        end
        operation_file = @save_config[hsh[:op_type]][:op_file]

        add_operation_file(operation_file, file_name) if operation_file
        puts "=> '#{operation_file}/#{hsh[:type]}' script done. #{Time.new - start} sn" if @debug_opt[:time] && @debug_opt[:console]
    end

    def add_operation_file(operation_file_name, file_name)
        puts "File '#{file_name}' record will be added into #{operation_file_name}" if @debug_opt[:console]
        File.open(operation_file_name, 'a') { |f| f.write("@#{file_name}\n") }
    end

    def default_params
        return [
            {
                type:       'index',
                connection: :dest,
                op_type:    :drop,
                lambda:     lambda { |arr| "DROP INDEX #{@connections[:dest].username}.#{arr[0]};\n" },
                query:      "SELECT object_name FROM user_objects WHERE status = 'VALID' AND object_type = 'INDEX' ORDER BY CREATED, TIMESTAMP\n"
            },
            {
                type:       'table',
                connection: :dest,
                op_type:    :drop,
                lambda:     lambda { |arr| "DROP TABLE #{@connections[:dest].username}.#{arr[0]};\n" },
                query:      "SELECT object_name FROM user_objects WHERE status = 'VALID' AND object_type = 'TABLE' ORDER BY CREATED, TIMESTAMP\n"
            },
            {
                type:       'sequence',
                connection: :dest,
                op_type:    :drop,
                lambda:     lambda { |arr| "DROP SEQUENCE #{@connections[:dest].username}.#{arr[0]};\n" },
                query:      "SELECT object_name FROM user_objects WHERE status = 'VALID' AND object_type = 'SEQUENCE' ORDER BY CREATED, TIMESTAMP\n"
            },
            {
                type:       'create_table',
                connection: :src,
                op_type:    :make,
                lambda:     lambda { |arr|  "-- original index create time: #{arr[0]}, last ddl time: #{arr[1]}\n" +
                                            arr[2].read.strip.gsub("\"#{@connections[:src].username}\"", "\"#{@connections[:dest].username}\"") .gsub(/\n  TABLESPACE \"[^"]*\"/,'') + ";\n\n"  },
                query:      "SELECT CREATED, LAST_DDL_TIME, DBMS_METADATA.GET_DDL(object_type, object_name, '#{@connections[:src].username}') val FROM user_objects WHERE status = 'VALID' AND object_type = 'TABLE' ORDER BY CREATED, TIMESTAMP\n"
            },
            {
                type:       'insert',
                connection: :src,
                op_type:    :make,
                lambda:     lambda { |arr| "INSERT INTO #{@connections[:dest].username}.#{arr[0]} \nSELECT * FROM #{@connections[:src].username}.#{arr[0]};\n\n" },
                query:      "SELECT object_name val FROM user_objects WHERE status = 'VALID' AND object_type = 'TABLE' ORDER BY CREATED, TIMESTAMP\n"
            },
            {
                type:       'sequence',
                connection: :src,
                op_type:    :make,
                lambda:     lambda { |arr|  "-- original index create time: #{arr[0]}, last ddl time: #{arr[1]}\n" +
                                            arr[2].read.strip.gsub("\"#{@connections[:src].username}\"", "\"#{@connections[:dest].username}\"") + ";\n"  },
                query:      "SELECT CREATED, LAST_DDL_TIME, DBMS_METADATA.GET_DDL(object_type, object_name, '#{@connections[:src].username}') val FROM user_objects WHERE status = 'VALID' AND object_type = 'SEQUENCE' ORDER BY CREATED, TIMESTAMP\n"
            },
            {
                type:       'index',
                connection: :src,
                op_type:    :make,
                lambda:     lambda { |arr|  "-- original index create time: #{arr[0]}, last ddl time: #{arr[1]}\n" +
                                            arr[2].read.strip.gsub("\"#{@connections[:src].username}\"", "\"#{@connections[:dest].username}\"").gsub(/\n  TABLESPACE \"[^"]*\"/,'') + ";\n\n"},
                query:      "SELECT CREATED, LAST_DDL_TIME, DBMS_METADATA.GET_DDL(object_type, object_name, '#{@connections[:src].username}') val FROM user_objects WHERE status = 'VALID' AND object_type = 'INDEX' ORDER BY CREATED, TIMESTAMP\n"
            }
        ]
    end
end