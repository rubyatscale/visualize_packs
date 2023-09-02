# visualize_packs
Visualize_packs helps you visualize the structure, intended and actual, of your package-based Ruby application.

This gem takes a minimal approach in that it only outputs a graph in the format of [graphviz](https://graphviz.org/)' [dot language](https://graphviz.org/doc/info/lang.html). Install graphviz and use one of the chains of commands from below to generate full or partial images of the graphs of your application.

## Visualize your entire application
```
bundle exec visualize_packs > packs.dot && dot packs.dot -Tpng -o packs.png && open packs.png
```

## packs.png for every package in your app

This will generate a local dependency diagram for every pack in your app

```
find . -iname 'package.yml' | sed 's/\/package.yml//g' | sed 's/\.\///' | xargs -I % sh -c "bundle exec visualize_packs --only=% > %/packs.dot && dot %/packs.dot -Tpng -o %/packs.png"
```

If your app is large and has many packages and todos, the above graphs will likely be too big. Try this version to get only the edges to and from the focus package for each diagram:

```
find . -iname 'package.yml' | sed 's/\/package.yml//g' | sed 's/\.\///' | xargs -I % sh -c "bundle exec visualize_packs --only=% --only-edges-to-focus > %/packs.dot && dot %/packs.dot -Tpng -o %/packs.png"
```


## Get help

```
bundle exec visualize_packs --help
```

## What outputs look like

![Sample diagrams produced](https://github.com/rubyatscale/visualize_packs/blob/main/diagram_examples.png?raw=true)

## Contributing

To contribute, install graphviz (and the `dot` command) and imagemagick. You must also have Ruby 3.2.2 and bundler installed. Then

```
./spec/test.sh
```

At the end of the test run, a new window will open up showing you a comparison of the old graphs (on the left) and the new graphs (on the right). Compare the visuals to make sure you're getting the changes you were expecting.

Once you are ready, run the following and commit the new `diagram_examples.png` and the new dot files with your changes:

```
./spec/update_cassettes.sh
```

Please check in a new `diagram_examples.png` only if there are actual visual changes.