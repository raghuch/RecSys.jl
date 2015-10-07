using Reactive
using JSON
global loaded = false
if !loaded
    include("ALS.jl")
    loaded = true
end

movie_meta = JSON.parse(readall("./data/movie_info.json"))

getfield(m, x, def="") = get(movie_meta, m, Dict()) |>
    (d -> get(d, x, def))

function show_movie_input(m, updates, idx)
    poster = image(getfield(m,"Poster", "http://uwatch.to/posters/placeholder.png"), alt=m) |>
       size(120px, 180px) |> vbox |> packacross(center)
    desc = vbox( fontsize(1em, m), getfield(m, "Genre")    )

    rating_slider = slider(0:5; name="rating-$idx", value=0, editable=true, pin=true, disabled=false, secondaryprogress=0)
    rating_widget = addinterpreter(r -> (idx, r), rating_slider) >>> updates

    content = vbox(poster,vskip(0.7em),
         getfield(m, "Title", m) |> fontsize(1.2em), vskip(0.5em),
         getfield(m, "Genre") |> fontsize(0.7em),
         vskip(1em), width(15em,rating_widget)) |> pad(1em)
    roundcorner(1em, content) |> fillcolor("#f1f1ff") |> pad(0.5em)

end

#function createratingvec(movielist, submitted_ratings)
	
#end


function main(window)
    push!(window.assets, "widgets")
    push!(window.assets, "layout2")

    movie_dataset = readdlm("./data/movies.csv",'\,')
    s = sampler()

    username = textinput("";name=:username, label="Your Name Here", floatinglabel=false, maxlength=256)
    btn = Input(leftbutton)
    submit_button = button("Submit") >>> btn

    vlist0 = vbox(title(1, "To get recommendations, rate some movies (0 for didn't watch and 1-5 for ratings)"), hskip(3em), width(20em, username))

### GET A LIST OF MOVIES, num_movies IS THE NUMBER OF MOVIES YOU WANT ###
## nrows is the number of rows in the display, and ncols is the number of columns per row.

    n = 20
    movielist = movie_dataset[floor(rand(n)*1600), :]
    init_ratings = zeros(Int, n)
    input = Input((0, 0))
    ratings = foldl(init_ratings, input) do state, update
        state[update[1]] = update[2]
        state
    end
    submitted_ratings = sampleon(btn, ratings)
    clicked = Input(0)
    #if(bool(value(sampleon(btn, clicked))))
        #push!(clicked, 1)
    #    lift(x -> 1, clicked)
    #end

    list = hbox([show_movie_input(m, input, idx) for (idx, m) in enumerate(movielist[:,2])]) |> wrap

    ratingvec = spzeros(1, size(movie_dataset)[1])
    map([1:size(movielist)[1]]) do movnum
        #ratingvec[int(movielist[movnum, 1])] = value(ratings))[movnum]
        println(value(submitted_ratings)[movnum])
    end 
    
    println(nonzeros(ratingvec))

    vbox(vlist0, ratings, submitted_ratings, vskip(3em),clicked, vskip(3em), width(10em, submit_button), vskip(3em), list, vskip(3em), [int(movielist[:, 1])], nonzeros(ratingvec) ) |> Escher.pad(2em)

end

