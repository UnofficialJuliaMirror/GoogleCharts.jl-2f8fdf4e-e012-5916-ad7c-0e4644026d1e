function charttype_to_dict(chart::GoogleChart)
    {
     :chart_type => chart.chart_type,
     :chart_id => chart.id,
     :width=>chart.width,
     :height=>chart.height,
     :chart_data => chart.data,
     :chart_options => JSON.json(chart.options)
     }
end

## take vector of google charts
function charts_to_dict(charts)

    packages = string(union([chart.packages for chart in charts]...))
    
   {:chart_packages => packages,
    :charts => [charttype_to_dict(chart) for chart in charts],
    :chart_xtra => join([chart.xtra for chart in charts],"\n")
   }
end

## Render charts
## io -- render to io stream
## fname -- render to file
## none -- create html file, show in browser
function render{T <: GoogleChart}(io::IO,
                                  charts::Vector{T},     # chart objects
                                  tpl::Union(Nothing, Mustache.MustacheTokens) # Mustache template. Default is entire page
                                  )
    
    details = charts_to_dict(charts)

    ## defaults
    _tpl = isa(tpl, Nothing) ? chart_tpl : tpl

    Mustache.render(io, _tpl, details)
end

function render{T <: GoogleChart}(fname::String,
                                  charts::Vector{T},
                                  tpl::Union(Nothing, Mustache.MustacheTokens))

    io = open(fname, "w")
    render(io, charts, tpl)
    close(io)
end
function render{T <: GoogleChart}(charts::Vector{T}, tpl::Union(Nothing, Mustache.MustacheTokens)) 
    fname = tempname() * ".html"
    render(fname, charts, tpl)
    open_url(fname)
end

## no tpl
render{T <: GoogleChart}(io::IO, charts::Vector{T}) = render(io, charts, nothing)
render{T <: GoogleChart}(fname::String, charts::Vector{T}) = render(fname, charts, nothing)
## no io or file name specified, render to browser
render{T <: GoogleChart}(charts::Vector{T}) = render(charts, nothing)
render{T <: GoogleChart}(io::Nothing, charts::Vector{T}, tpl::Union(Nothing, Mustache.MustacheTokens)) = render(charts, tpl)

render(io::IO, chart::GoogleChart, tpl::Union(Nothing, Mustache.MustacheTokens)) = render(io, [chart], tpl)
render(io::IO, chart::GoogleChart) = render(io, chart, nothing)
render(fname::String, chart::GoogleChart, tpl::Union(Nothing, Mustache.MustacheTokens)) = render(fname, [chart], tpl)
render(fname::String, chart::GoogleChart) = render(fname, [chart], nothing)

render(chart::GoogleChart, tpl::Union(Nothing, Mustache.MustacheTokens)) = render([chart], tpl)
render(chart::GoogleChart) = render([chart])
render(io::Nothing, chart::GoogleChart, tpl::Union(Nothing, Mustache.MustacheTokens)) = render([chart], tpl)
render(io::Nothing, chart::GoogleChart) = render([chart], nothing)

## display to browser
function Base.repl_show(io::IO, chart::GoogleChart)
    if io === STDOUT
        render(nothing, chart)
    else
        show(io, chart)
    end
end
Base.show(io::IO, chart::GoogleChart) = print(io, "<plot>")

## for using within Gadfly.weave:
gadfly_weave_tpl = "
<div id={{:id}} style=\"width:{{:width}}px; height:{{:height}}px;\"></div>
<script>
var {{:id}}_data = {{{:chart_data}}};
var {{:id}}_options = {{{:chart_options}}};
var {{:id}}_chart = new google.visualization.{{:chart_type}}(document.getElementById('{{:id}}'));{{:id}}_chart.draw({{:id}}_data,  {{:id}}_options);
</script>
"

## this is used by weave...
function gadfly_format(x::CoreChart)
    d = {:id => x.id,
         :width => 600,
         :height => 400,
         :chart_data => x.data,
         :chart_options => json(x.options),
         :chart_type => x.chart_type
         }
    Mustache.render(gadfly_weave_tpl, d)
end


        

## IJulia support
## Until this migrates into Base, we need to copy and past this in to get graphics to work
## within IJulia
#
# import Multimedia.writemime # change to Base.writemime once Julia #3932 is merged
# function writemime(io::IO, ::@MIME("text/html"), p::GoogleCharts.CoreChart) 
#     out = GoogleCharts.gadfly_format(p)
#     ## don't like this, shouldn't have to add each time these lines
#     out = "
# <script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>
# <script>setTimeout(function(){google.load('visualization', '1', {'callback':'', 'packages':['corechart']})}, 2);</script>
# " *  GoogleCharts.gadfly_format(p)

#     print(io, out)
# end
