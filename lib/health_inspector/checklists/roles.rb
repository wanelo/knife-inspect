require "chef/role"
require 'yajl'

module HealthInspector
  module Checklists
    class Role < Pairing
      include ExistenceValidations
      include JsonValidations
    end

    class Roles < Base
      title "roles"

      def each_item
        all_item_names.each do |name|
          yield load_item(name)
        end
      end

      def all_item_names
        super.sort { |a, b| a.include?('/') ? -1 : 1 }.uniq{|item| item.split('/').last }.sort
      end

      def load_item(name)
        Role.new(@context,
          :name   => name,
          :server => load_item_from_server(name),
          :local  => load_item_from_local(name)
        )
      end

      def server_items
        @server_items ||= Chef::Role.list.keys
      end

      def local_items
        Dir.chdir("#{@context.repo_path}/roles") do
          Dir["**/*.{rb,json,js}"].map { |e| e.gsub(/\.(rb|json|js)/, '') }
        end
      end

      def load_item_from_server(name)
        role = Chef::Role.load(name.split('/').last)
        role.to_hash
      rescue
        nil
      end

      def load_item_from_local(name)
        filename = local_items.grep(/(^|\/)#{name}$/).first
        load_ruby_or_json_from_local(Chef::Role, "roles", filename)
      end
    end

  end
end
