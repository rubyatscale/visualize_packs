# visualize_packwerk

This gem contains rake tasks to help visualize relationships between packwerk packs.

# Usage
## Building a package graph for a selection of packages (owned by 5 teams max)
```
bin/rails visualize_packwerk:package_relationships['packs/pack1','packs/pack2']
```

# Building a package graph for specific teams (5 teams max)
```
bin/rails visualize_packwerk:package_relationships_for_teams['Team1','Team2']
```

# Building a package graph for all packages (this is slow and produces a huge file)
```
bin/rails visualize_packwerk:package_relationships
```

# Building a TEAM graph for specific teams
```
bin/rails visualize_packwerk:team_relationships['Team1','Team2']
```

# Building a TEAM graph for all teams (this is slow and produces a huge file)
```
bin/rails visualize_packwerk:team_relationships
```

# Want to change something or add a feature?
Submit a PR or post an issue!
