#=
PLANE SWEEP ALGORITHM for RECTANGLES

    input : a list of rectangles(index, (x0, y0), (x1, y1))
    output : 
        1. a list of rectangles where the rectangles are intersected
            ex) ((1, 1), (5, 3)) and ((2, 2), (4, 6)) => (2, 4, 2, 3) in l, r, b, t format
        2. HCG (Horizontal Containment Graph) as a matrix + png file
            ex) if rect2 is right of rect1, hcg[rect1, rect2] = 1 / else 0
=#

# import Pkg
# Pkg.add("Plots")
# Pkg.add("GraphRecipes")
using Plots
using GraphRecipes

mutable struct Point
    index::Int  # index of the rectangle
    value::Int  # 1-D coordinate
    is_start::Bool  # true if the point is left / false if the point is right
end

mutable struct Rect
    index::Int
    l::Int  # left
    r::Int  # right
    b::Int  # bottom
    t::Int  # top

    function Rect(index::Int, coords1::Tuple{Int, Int}, coords2::Tuple{Int, Int})
        l = min(coords1[1], coords2[1])
        r = max(coords1[1], coords2[1])
        b = min(coords1[2], coords2[2])
        t = max(coords1[2], coords2[2])
        new(index, l, r, b, t)
    end
end

function get_checkpoint_list(rect_list::Vector{Rect})
    # plane-sweep algorithm works by checking when a rect enters/leaves the active_list
    # checkpoint_list is a sorted list containing the points with left/right x-coordinates of each rect
    # loops over the checkpoint_list in f(evaluate) 
    checkpoint_list = Vector{Point}()

    for rect in rect_list
        push!(checkpoint_list, Point(rect.index, rect.l, true))
        push!(checkpoint_list, Point(rect.index, rect.r, false))
    end

    sort!(checkpoint_list, by = x -> (x.value, x.is_start))

    return checkpoint_list
end

function get_rect_by_index(rect_list::Vector{Rect}, index::Int)
    # helper function for getting the rect object by index
    for rect in rect_list
        if rect.index == index
            return rect
        end
    end
end

function evaluate(rect_list::Vector{Rect})
    # INTERSECTION + HCG
    # evaluate the intersection of the rectangles and creates the HCG
    checkpoint_list = get_checkpoint_list(rect_list)
    active_list = Vector{Rect}()
    intersection_list = Vector{Tuple{Rect, Rect, Int, Int, Int, Int}}()

    # HCG is represented as a nxn matrix
    # if rect2 is right of rect1, hcg[rect1, rect2] = 1 / else 0
    # 현재 r값과 l값이 모두 큰 경우에만 hcg에 1을 넣어주도록 설정(가장 가까운 rect 하나만 탐색)
    n_rects = length(rect_list)
    hcg = zeros(Int, n_rects, n_rects)


    for checkpoint in checkpoint_list
        if !checkpoint.is_start # when a rect is leaving the active_list
            deleteat!(active_list, findfirst(x -> x.index == checkpoint.index, active_list))
            deleted_rect = get_rect_by_index(rect_list, checkpoint.index)
            for active_rect in active_list  # when a rect is leaving the active_list create a hcg connection
                if (deleted_rect.l < active_rect.l) && (deleted_rect.r < active_rect.r) # find the first rect that is right of the deleted rect
                    hcg[deleted_rect.index, active_rect.index] = 1
                    break
                end
            end
        else    # when a rect is entering the active_list
            new_rect = get_rect_by_index(rect_list, checkpoint.index)
            for rect in active_list
                # search through all the active rects to find the intersection
                max_b = max(rect.b, new_rect.b)
                min_t = min(rect.t, new_rect.t)
                if max_b < min_t
                    # println("Intersection found between ", rect, " and ", new_rect)
                    max_l = max(rect.l, new_rect.l)
                    min_r = min(rect.r, new_rect.r)
                    push!(intersection_list, (rect, new_rect, max_l, min_r, max_b, min_t))
                    # println("Intersection : ($max_l, $min_r, $max_b, $min_t)")
                end
            end
            push!(active_list, new_rect)
        end
    end
    return intersection_list, hcg
end

function draw_graph(hcg::Matrix{Int})
    # save the HCG as a graph
    p = graphplot(hcg, names = 1:size(hcg, 1), curvature_scalar = 0.1)
    savefig(p, "hcg.png")
end

function draw_rects(rect_list::Vector{Rect})
    # helper function to draw the rectangles in terminal
    
    # Determine the maximum width and height of the drawing area
    max_x = 0
    max_y = 0
    for rect in rect_list
        max_x = max(max_x, rect.r)
        max_y = max(max_y, rect.t)
    end

    # Create a 2D array (matrix) to represent the drawing area
    drawing_area = fill(' ', max_y + 1, (max_x + 1) * 2)

    # Iterate through each rectangle and fill the boundary positions in the matrix
    for rect in rect_list
        x0, y0, x1, y1 = rect.l, rect.b, rect.r, rect.t
        x_min, x_max = min(x0, x1), max(x0, x1)
        y_min, y_max = min(y0, y1), max(y0, y1)

        # Draw top edge with '__'
        for x in x_min:x_max
            drawing_area[y_min + 1, (x + 1) * 2 - 1] = '_'
            drawing_area[y_min + 1, (x + 1) * 2] = '_'
        end

        # Draw bottom edge with '¯¯'
        for x in x_min:x_max
            drawing_area[y_max + 1, (x + 1) * 2 - 1] = '¯'
            drawing_area[y_max + 1, (x + 1) * 2] = '¯'
        end

        # Draw left and right edges with '|'
        for y in y_min:y_max
            drawing_area[y + 1, (x_min + 1) * 2 - 1] = '|'
            drawing_area[y + 1, (x_max + 1) * 2] = '|'
        end
    end

    # Print the matrix to the terminal
    println("Drawing Rectangles:")
    for row in reverse(eachrow(drawing_area))
        println(join(row))
    end
end


function main()
    rect_list = Vector{Rect}()
    push!(rect_list, Rect(1, (1, 1), (5, 3)))
    push!(rect_list, Rect(2, (2, 2), (4, 6)))
    push!(rect_list, Rect(3, (3, 3), (7, 4)))
    push!(rect_list, Rect(4, (6, 1), (8, 5)))
    push!(rect_list, Rect(5, (7, 2), (9, 7)))

    draw_rects(rect_list)

    intersection_list, hcg = evaluate(rect_list)
    println("Intersection list:")
    for intersection in intersection_list
        rect1, rect2, l, r, b, t = intersection
        println("Rect$(rect1.index) and Rect$(rect2.index) intersect at ($l, $r, $b, $t)")
    end
    println("\nHCG:")
    for row in eachrow(hcg)
        println(join(row))
    end
    draw_graph(hcg)
end


if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
