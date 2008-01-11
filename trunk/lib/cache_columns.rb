module CacheColumns
  module ActiveRecord
    @@columns = {}

    def self.included(base)
      base.instance_eval do
        alias old_columns columns
        alias old_reset_column_information reset_column_information

        def columns
          if  @@columns[table_name].nil?
            @@columns[table_name] = connection.columns(table_name, "#{name} Columns")
            @@columns[table_name].each {|column| column.primary = column.name == primary_key}
          end
          @@columns[table_name]
        end

        #  # Resets all the cached information about columns, which will cause them to be reloaded on the next request.
        def reset_column_information
          generated_methods.each { |name| undef_method(name) }
          @column_names = @columns_hash = @content_columns = @dynamic_methods_hash = @read_methods = @inheritance_column = nil
          @@columns.delete(table_name)
        end

        def reset_column_cache #:nodoc:
          @@columns = {}
        end
      end
    end

    module ActionController
      def self.included(base)
        base.instance_eval do
          alias old_cleanup_application cleanup_application
          # Cleanup the application by clearing out loaded classes so they can
          # be reloaded on the next request without restarting the server.
          def cleanup_application(force = false)
            if Dependencies.load? || force
              ActiveRecord::Base.reset_subclasses if defined?(ActiveRecord)
              Dependencies.clear
              #ActiveRecord::Base.clear_reloadable_connections! if defined?(ActiveRecord)
              if defined?(ActiveRecord)
                ActiveRecord::Base.clear_reloadable_connections!
                ActiveRecord::Base.reset_column_cache
              end
            end
          end
        end
      end
    end
  end
end
