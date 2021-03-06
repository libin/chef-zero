require 'json'
require 'chef/exceptions' # Needed so Chef::Version/VersionConstraint load
require 'chef/version_class'
require 'chef/version_constraint'
require 'chef_zero/rest_base'
require 'chef_zero/data_normalizer'

module ChefZero
  module Endpoints
    # Common code for endpoints that return cookbook lists
    class CookbooksBase < RestBase
      def format_cookbooks_list(request, cookbooks_list, constraints = {}, num_versions = nil)
        results = {}
        filter_cookbooks(cookbooks_list, constraints, num_versions) do |name, versions|
          versions_list = versions.map do |version|
            {
              'url' => build_uri(request.base_uri, ['cookbooks', name, version]),
              'version' => version
            }
          end
          results[name] = {
            'url' => build_uri(request.base_uri, ['cookbooks', name]),
            'versions' => versions_list
          }
        end
        results
      end

      def filter_cookbooks(cookbooks_list, constraints = {}, num_versions = nil)
        cookbooks_list.keys.sort.each do |name|
          constraint = Chef::VersionConstraint.new(constraints[name])
          versions = []
          cookbooks_list[name].keys.sort_by { |version| Chef::Version.new(version) }.reverse.each do |version|
            break if num_versions && versions.size >= num_versions
            if constraint.include?(version)
              versions << version
            end
          end
          yield [name, versions]
        end
      end

      def recipe_names(cookbook_name, cookbook)
        result = []
        if cookbook['recipes']
          cookbook['recipes'].each do |recipe|
            if recipe['path'] == "recipes/#{recipe['name']}" && recipe['name'][-3..-1] == '.rb'
              if recipe['name'] == 'default.rb'
                result << cookbook_name
              end
              result << "#{cookbook_name}::#{recipe['name'][0..-4]}"
            end
          end
        end
        result
      end
    end
  end
end
