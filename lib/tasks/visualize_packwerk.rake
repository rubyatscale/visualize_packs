# typed: strict

module PackwerkVisualizations
  class TaskLoader
    include Rake::DSL
    extend T::Sig

    sig { void }
    def create_tasks!
      namespace(:visualize_packwerk) do
        # This creates the array of symbols that are needed to declare an argument to a rake task
        package_args = (1..100).map { |i| "package#{i}".to_sym }

        desc('Graph packages')
        task(:package_relationships, package_args => :environment) do |_task, args|
          show_all_packs = args.to_hash.values.none?
          packages = if show_all_packs
            ParsePackwerk.all
          else
            args.to_hash.values.map do |pack_name|
              found_package = ParsePackwerk.all.find { |p| p.name == pack_name }
              if found_package.nil?
                abort "Could not find pack with name: #{pack_name}"
              end

              found_package
            end
          end

          PackageRelationships.new.create_package_graph!(packages, show_all_packs: show_all_packs)
        end

        # This creates the array of symbols that are needed to declare an argument to a rake task
        team_args = (1..5).map { |i| "team#{i}".to_sym }

        desc('Graph packages for teams')
        task(:package_relationships_for_teams, team_args => :environment) do |_task, args|
          teams = args.to_hash.values.map do |team_name|
            team = CodeTeams.find(team_name)
            if team.nil?
              abort("Could not find team with name: #{team_name}. Check your config/teams/subdirectory/team.yml for correct team spelling, e.g. `Product Infrastructure`")
            end

            team
          end

          PackageRelationships.new.create_package_graph_for_teams!(teams)
        end

        desc('Graph team relationships')
        task(:team_relationships, team_args => :environment) do |_task, args|
          show_all_teams = args.to_hash.values.none?
          teams = if show_all_teams
            CodeTeams.all
          else
            args.to_hash.values.map do |team_name|
              team = CodeTeams.find(team_name)
              if team.nil?
                abort("Could not find team with name: #{team_name}. Check your config/teams/subdirectory/team.yml for correct team spelling, e.g. `Product Infrastructure`")
              end

              team
            end
          end

          PackageRelationships.new.create_team_graph!(teams, show_all_teams: show_all_teams)
        end
      end
    end
  end
end

PackwerkVisualizations::TaskLoader.new.create_tasks!
