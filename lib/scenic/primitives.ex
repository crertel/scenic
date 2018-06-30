#
#  Created by Boyd Multerer April 30, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# convenience functions for adding basic primitives to a graph.
# this module should be updated as new primitves area dded

defmodule Scenic.Primitives do
  alias Scenic.Primitive
  alias Scenic.Graph

  # import IEx

  @moduledoc """
  A set of primitive helper functions to make it easier to build
  complex graphs.

  In general, each helper function is of the form
      def some_primitive( graph, data, opts \\ [] )

  They each accept a graph as the first parameter and return a graph
  with the new primitive appended at the node currently being built.
  This means that the new item will be appended at the root if the
  original graph is passed in. If this call is made inside of a group
  callback, then primitive is added to that group.

  In this way, a graph can be built like this:

      @graph Graph.build()
      |> text( "Hello World", id: :hello )


      @graph Graph.build
      |> text( "Hello World", translate: {10, 100}, rotate: {0.1} )

      @graph Graph.build
      |> graph( fn(graph) ->
        graph
        |> text( "Hello World" )
      end, translate: {10, 100})

  ## First parameter - the graph

  The first parameter of each helper is the graph you are building. I suggest
  pass it along in a function pipe as above.

  ## Second parameter - primitive specific data

  The second parameter is data specific to each primitive. See the documentation
  for the primitives to see what to pass in. In general, if it makes sense,
  you can pass in either a simplified form of the data or a explicit form.

  For example, the text/3 function accepts two data forms. The simple form is
  just a string, which will be rendered at the position 0,0. You would then
  move it about with transforms like this.

      |> text("Hello World")

  The explicit form is an x/y position and the string, which will be rendered
  at that position without a transform.

      |> text( {{10, 20}, "Hello World"} )

  ## Third parameter - options

  The third paramter, opts, is a keyword list of options, none of which are
  required, but some of which are regularly used. These options fall into one
  of three categories: standard, styles and transforms.

  ### Standard options

  Standard options, such as :id and :tags are to make it easier to access the
  items in a graph. Standard options are not inherited by items down the graph.

  ### Style options

  Style options affect the way primitives are drawn. They include options such
  as :color, :border_width, :font and many more. See the Styles documentation
  for the full list. Style options are inherited down the graph. In other words,
  if you set a style on the root of the graph like this:
  Graph.build( font: {:roboto, 20}, then all text items in all groups will be
  rendered with the Roboto font with a point size of 20 unless they set a
  different font style.

  Not every primtitive accepts every style. For example, it doesn't make much
  sense to apply a font to a rectangle. If you try, the rectangle will ignore
  that value. See the documentation for each primitive to see what styles
  they pay attention to.

  ### Transform options

  Transform options affect the size, position and rotation of elements in the
  graph. Any transform you can express as a 4x4 matrix of floats, you can apply
  to any primitive in the graph, including groups and scene_refs.

  Transform options are applied on the element the are specified on. However, if
  you specify a transform on a group, then all the elements will ahve that transform
  applied to them as well.

  This is done mathematically as a "stack" of transforms. As the renderer
  traverses up and down the graph, transforms are pushed and popped from the
  matrix stack as appropriate.

  ## Draw Order
  
  One final note. Primitives will be drawn in the order you add them to the graph.
  For example, the graph below draws text on top of a filled rectangle. If the order
  of the text and rectangle were reversed, they would both still be rendered, but
  the text would not be visible because the rectangle would cover it up.

      @graph Graph.build( font: {:roboto, 20} )
      |> rect( {100, 200}, color: :blue )
      |> text( "Hello World", id: :hello, translate: {10, 10} )

  """


  #--------------------------------------------------------
  def arc( graph_or_primitive, data, opts \\ [] )

  def arc( gp, {radius, start, finish}, opts ), do:
    arc( gp, {{0,0}, radius, start, finish}, opts )

  def arc( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Arc, data, opts )
  end

  def arc( %Primitive{module: Primitive.Arc} = p, data, opts ) do
    modify( p, data, opts )
  end


  #--------------------------------------------------------
  def circle( graph_or_primitive, data, opts \\ [] )

  def circle( gp, radius, opts ) when is_number(radius), do:
    circle( gp, {{0,0}, radius}, opts )

  def circle( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Circle, data, opts )
  end

  def circle( %Primitive{module: Primitive.Circle} = p, data, opts ) do
    modify( p, data, opts )
  end


  #--------------------------------------------------------
  def ellipse( graph_or_primitive, data, opts \\ [] )

  def ellipse( gp, {r1, r2}, opts ) when is_number(r1) and is_number(r2), do:
    ellipse( gp, {{0,0}, r1, r2}, opts )

  def ellipse( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Ellipse, data, opts )
  end

  def ellipse( %Primitive{module: Primitive.Ellipse} = p, data, opts ) do
    modify( p, data, opts )
  end

  #--------------------------------------------------------
  def group( graph_or_primitive, builder, opts \\ [] )
  def group( %Graph{} = graph, builder, opts ) when is_function(builder, 1) do
    Primitive.Group.add_to_graph(graph, builder, opts)
  end


  #--------------------------------------------------------
  @doc """
  Add a line to a graph

  Lines are pretty simple, so there is only one form for the primitive
  specific data. That is a typle of points describing where to start
  drawing the line and where to end it.

      { {from_x, from_y}, {to_x,to_y} }

  The following example will draw a diagonal line from the upper left
  corner `{0,0}` to the point `{100,200}`, which is down and to the right.

      |> line( {{0,0}, {100,200}} )

  ### Styles

  lines honor the following styles
  
  * `:hidden` - If true the line is rendered. If false, it is skipped. The default
    is to render the primitive if hidden is not set.
  * `:color` - The color to draw the line in. Can be either one color or
    two, which will be applied to teh two ends of the line. The default color is
    `:white` if `:color` is not set
  * `:line_width` - The width of the line. The default is 1 if not set.
  * `:line_stipple` - The pattern of the line. This is a bit complicated and
    may change in the future. For now, stick with these values to be safe:
    `:solid`, `:dot`, `:dash`, and `:dash_dot`. If you want to get experimental, you can
    pass in opengl 2 styles stipple patterens. The default is  `:solid` if not set.

      |> line( {{0,0}, {100,200}}, color: blue, line_width: 4, line_stipple: :dash )

  See the style documentation for more detail.
  """
  def line( graph_or_primitive, data, opts \\ [] )

  def line( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Line, data, opts )
  end

  def line( %Primitive{module: Primitive.Line} = p, data, opts ) do
    modify( p, data, opts )
  end

  #--------------------------------------------------------
  def path( graph_or_primitive, data, opts \\ [] )

  def path( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Path, data, opts )
  end

  def path( %Primitive{module: Primitive.Path} = p, data, opts ) do
    modify( p, data, opts )
  end



  #--------------------------------------------------------
  def quad( graph_or_primitive, data, opts \\ [] )

  def quad( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Quad, data, opts )
  end

  def quad( %Primitive{module: Primitive.Quad} = p, data, opts ) do
    modify( p, data, opts )
  end


  #--------------------------------------------------------
  def rect( graph_or_primitive, data, opts \\ [] ) do
    rectangle( graph_or_primitive, data, opts )
  end

  def rectangle( graph_or_primitive, data, opts \\ [] )

  def rectangle( gp, {width, height}, opts ) do
    rectangle( gp, {{0,0}, width, height}, opts )
  end

  def rectangle( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Rectangle, data, opts )
  end

  def rectangle( %Primitive{module: Primitive.Rectangle} = p, data, opts ) do
    modify( p, data, opts )
  end


  #--------------------------------------------------------
  def rrect( graph_or_primitive, data, opts \\ [] ) do
    rounded_rectangle( graph_or_primitive, data, opts )
  end

  def rounded_rectangle( graph_or_primitive, data, opts \\ [] )

  def rounded_rectangle( gp, {width, height, radius}, opts ) do
    rounded_rectangle( gp, {{0,0}, width, height, radius}, opts )
  end

  def rounded_rectangle( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.RoundedRectangle, data, opts )
  end

  def rounded_rectangle( %Primitive{module: Primitive.RoundedRectangle} = p, data, opts ) do
    modify( p, data, opts )
  end


  #--------------------------------------------------------
  def scene_ref( graph_or_primitive, data, opts \\ [] )

  # def scene_ref( %Graph{} = graph, {:graph,_,_} = key, opts ) do
  #   Primitive.SceneRef.add_to_graph( graph, key, opts )
  # end

  # def scene_ref( %Graph{} = graph, name_pid, opts ) when
  # is_atom(name_pid) or is_pid(name_pid) do
  #   Primitive.SceneRef.add_to_graph( graph, {name_pid, nil}, opts )
  # end

  # def scene_ref( %Graph{} = graph, {name,_} = data, opts ) when is_atom(name) do
  #   Primitive.SceneRef.add_to_graph( graph, data, opts )
  # end

  # def scene_ref( %Graph{} = graph, {pid,_} = data, opts ) when is_pid(pid) do
  #   Primitive.SceneRef.add_to_graph( graph, data, opts )
  # end

  # def scene_ref( %Graph{} = graph, {{module,_},_} = data, opts ) when is_atom(module) do
  #   Primitive.SceneRef.add_to_graph( graph, data, opts )
  # end

  def scene_ref( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.SceneRef, data, opts )
  end

  # def scene_ref( %Primitive{module: Primitive.SceneRef} = p, data, opts ) do
  #   modify( p, data, opts )
  # end


  #--------------------------------------------------------
  def sector( graph_or_primitive, data, opts \\ [] )

  def sector( gp, {radius, start, finish}, opts ), do:
    sector( gp, {{0,0}, radius, start, finish}, opts )

  def sector( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Sector, data, opts )
  end

  def sector( %Primitive{module: Primitive.Sector} = p, data, opts ) do
    modify( p, data, opts )
  end

  #--------------------------------------------------------
  def text( graph_or_primitive, data, opts \\ [] )

  def text( gp, text, opts ) when is_bitstring(text) do
    text( gp, {{0,0}, text}, opts )
  end

  def text( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Text, data, opts )
  end

  def text( %Primitive{module: Primitive.Text} = p, data, opts ) do
    modify( p, data, opts )
  end

  #--------------------------------------------------------
  def triangle( graph_or_primitive, data, opts \\ [] )
  
  def triangle( %Graph{} = g, data, opts ) do
    add_to_graph( g, Primitive.Triangle, data, opts )
  end

  def triangle( %Primitive{module: Primitive.Triangle} = p, data, opts ) do
    modify( p, data, opts )
  end


  #============================================================================
  # generic workhorse versions

  defp add_to_graph( %Graph{} = g, mod, data, opts ) do
    mod.verify!(data)
    mod.add_to_graph(g, data, opts)
  end

  defp modify( %Primitive{module: mod} = p, data, opts ) do
    mod.verify!(data)
    p
    |> Primitive.put( data )
    |> Primitive.update_opts( opts )
  end


end






