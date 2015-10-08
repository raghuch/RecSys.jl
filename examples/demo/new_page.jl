using Reactive
using JSON

include("index.jl")

function show_movie_input(meta, m, updates, idx)
    poster = image(getfield(meta, m,"Poster", "http://uwatch.to/posters/placeholder.png"), alt=m) |>
       size(120px, 180px) |> vbox |> packacross(center)
    desc = vbox( fontsize(1em, m), getfield(meta, m, "Genre")    )


    rating_slider = slider(0:5; name="rating-$idx", value=0, editable=true, pin=true, disabled=false, secondaryprogress=0)
    rating_widget = addinterpreter(r -> (idx, r), rating_slider) >>> updates

    #user_ratingᵗ = lift(user_rating) do
    #end

    content = vbox(poster,vskip(0.7em),
         getfield(meta, m, "Title", m) |> fontsize(1.2em), vskip(0.5em),
         getfield(meta, m, "Genre") |> fontsize(0.7em),
         vskip(1em), width(15em,rating_widget)) |> pad(1em)
    roundcorner(1em, content) |> fillcolor("#f1f1ff") |> pad(0.5em)

end


function main(window)
    push!(window.assets, "widgets")
    push!(window.assets, "layout2")

    R = Rating("./data/ml-100k/u1.base",'\t',false)
    U , M = factorize(R,10,10)
    movie_meta = JSON.parse(readall("./data/movie_info.json"))

    movie_dataset = readdlm("./data/movies.csv",'\,')
    s = sampler()

    username = textinput("";name=:username, label="Your Name Here", floatinglabel=false, maxlength=256)
    #submit_button = button(      map(pad([left, right], 1em), ["Submit", "Now"]) ; name=:submit, raised=true, disabled=false, noink=true )
    btn = Input(leftbutton)
    submit_button = button("Submit") >>> btn

    vlist0 = vbox(title(1, "To get recommendations, rate some movies (0 for didn't watch and 1-5 for ratings)"), hskip(3em), width(20em, username))


    n = 15
    nummovies = size(movie_dataset)[1]
    movielist = movie_dataset[floor(rand(n)*nummovies), :]
    movieindices = int(movielist[:, 1])
    userratingvec = spzeros(nummovies, 1)

    init_ratings = zeros(Int, n)
    input = Input((0, 0))
    ratings = foldl(init_ratings, input) do state, update
        state[update[1]] = update[2]
        state
    end

    submitted_ratings = foldl(userratingvec, sampleon(btn, ratings) ) do ratingvec, new_vec
        ratingvec=sparse(movieindices,int(ones(n)),new_vec)
        #println(movieindices, new_vec, ratingvec)
        ratingvec
    end

    #ratingvec = zeros(size(movie_dataset))

    list = hbox([show_movie_input(movie_meta, m, input, idx) for (idx, m) in enumerate(movielist[:,2])]) |> wrap

    vbox(
        vlist0,
        ratings,
        submitted_ratings,
        vskip(3em),
        width(10em, submit_button),
        vskip(3em),
        list,
        show_list(2, R, U, M, 20, movie_meta)
    ) |> Escher.pad(2em)

end
