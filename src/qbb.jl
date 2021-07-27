export quickbb

# *************************************************************************************** #
#                       Functions to use Gogate's QuickBB binary
# *************************************************************************************** #

"""
    quickbb(G::lg.AbstractGraph; 
            time::Integer=0, 
            order::Symbol=:_, 
            verbose::Bool=false )::Tuple{Int, Array{Int, 1}}

Call Gogate's QuickBB binary on the provided graph and return the resulting perfect 
elimination ordering. 

A dictionary containing metadata for the elimination order is also returned. Metadata
includes: 
- `:treewidth` of the elimination order,  
- `:time` taken by quickbb to find the order,
- `:lowerbound` for the treewidth computed by quickbb,
- `:is_optimal` a boolean indicating if the order as optiaml treewidth.

The QuickBB algorithm is described in arXiv:1207.4109v1

# Keywords
- `time::Integer=0`: the number of second to run the quickbb binary for.
- `order::Symbol=:_`: the branching order to be used by quickbb (:random or :min_fill).
- `lb::Bool=false`: set if a lowerbound for the treewidth should be computed.
- `verbose::Bool=false`: set to true to print quickbb stdout and stderr output.
- `proc_id::Integer=0`: used to create uniques names of files for different processes.
"""
function quickbb(G::lg.AbstractGraph; 
                time::Integer=0, 
                order::Symbol=:_, 
                lb::Bool=false,
                verbose::Bool=false,
                proc_id::Integer=0)

    # Assuming Gogate's binary can be run using docker in quickbb/ located in same
    # directory as the current file.
    qbb_dir = dirname(@__FILE__) * "/quickbb"
    work_dir = pwd()

    try
        cd(qbb_dir)
        # Write the graph G to a CNF file for the quickbb binary and clear any output from
        # previous runs.
        mktempdir(qbb_dir) do tdir
            tdir = basename(tdir)
            qbb_out = tdir * "/qbb_$(proc_id).out" 
            graph_cnf = tdir * "/graph_$(proc_id).cnf"
            graph_to_cnf(G, graph_cnf)

            # Write the appropriate command to call quickbb with the specified options.
            if Sys.isapple()
                quickbb_cmd = ["docker", "run", "-v", "$(qbb_dir):/app", "myquickbb"]
                if order == :random
                    append!(quickbb_cmd, ["--random-ordering"])
                elseif order == :min_fill
                    append!(quickbb_cmd, ["--min-fill-ordering"])
                end
                if time > 0
                    append!(quickbb_cmd, ["--time", string(time)])
                end
                if lb
                    append!(quickbb_cmd, ["--lb"])
                end
                append!(quickbb_cmd, ["--outfile", qbb_out, "--cnffile", graph_cnf])
                quickbb_cmd = Cmd(quickbb_cmd)

                # run the quickbb command.
                if verbose
                    run(quickbb_cmd)
                else
                    out = Pipe()
                    run(pipeline(quickbb_cmd, stdout=out, stderr=out))
                end

            elseif Sys.islinux()
                quickbb_cmd = ["./quickbb_64"]
                if order == :random
                    append!(quickbb_cmd, ["--random-ordering"])
                elseif order == :min_fill
                    append!(quickbb_cmd, ["--min-fill-ordering"])
                end
                if time > 0
                    append!(quickbb_cmd, ["--time", string(time)])
                end
                if lb
                    append!(quickbb_cmd, ["--lb"])
                end
                append!(quickbb_cmd, ["--outfile", qbb_out, "--cnffile", graph_cnf])
                quickbb_cmd = Cmd(quickbb_cmd)

                # run the quickbb command.
                if verbose
                    run(quickbb_cmd)
                else
                    out = Pipe()
                    run(pipeline(quickbb_cmd, stdout=out, stderr=out))
                end
            end

            # Read in the output from quickbb.
            metadata = Dict{Symbol, Any}()
            lines = readlines(qbb_out)
            metadata[:treewidth] = parse(Int, split(lines[1])[end])
            if lb
                perfect_elimination_order = parse.(Int, split(lines[end-1]))
                metadata[:lowerbound] = parse(Int, split(lines[2])[end])
                metadata[:time] = parse(Float64, split(lines[3])[end])
                metadata[:is_optimal] = length(split(lines[4])) == 4
            else
                perfect_elimination_order = parse.(Int, split(lines[end]))
                metadata[:time] = parse(Float64, split(lines[2])[end])
                metadata[:is_optimal] = length(split(lines[3])) == 4
            end
            return perfect_elimination_order, metadata
        end

    finally
        # Clean up before returning results.
        cd(work_dir)
    end
end

# function quickbb(G::LabeledGraph; 
#                 time::Integer=0, 
#                 order::Symbol=:_, 
#                 lb::Bool=false,
#                 verbose::Bool=false,
#                 proc_id::Integer=0)

#     peo, metadata = quickbb(G.graph; time=time, order=order, lb=lb, 
#                             verbose=verbose, proc_id=proc_id)

#     # Convert the perfect elimination order to an array of vertex labels before returning
#     [G.labels[v] for v in peo], metadata
# end