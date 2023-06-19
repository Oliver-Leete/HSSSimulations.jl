const time_format = "HH:MM:SS"

"""
$(TYPEDSIGNATURES)

`debugGroups` is a list of groups of debug messages to log to the `logFile`. If it is set to true
then all log groups in the package are used (see [`package_groups`](@ref)), if it is set to false
then no log groups are used.

User log groups can be added to the list, simple add your own string to the list and then set debug
messages with the `_group` field set to your string.

There is a special group called `"misc"` that will catch any group not in the
[`package_groups`](@ref) list or in any additional group given by the user to the debugGroups list.
"""
function makeLogger(debugGroups, logFile)
    named_groups = package_groups ∪ debugGroups
    loggers = []
    fileLogger = FileLogger(logFile)
    for group in debugGroups
        if group == "core"
            timed = TransformerLogger(fileLogger) do log
                return merge(
                    log,
                    (;
                        message=string(
                            "[",
                            Dates.format(now(), time_format),
                            "] ",
                            log.message,
                        )
                    ),
                )
            end
            logger = EarlyFilteredLogger(log -> (log.group == "core"), timed)
        elseif group == "misc"
            logger = EarlyFilteredLogger(log -> (log.group ∉ named_groups), fileLogger)
        else
            logger = EarlyFilteredLogger(log -> (log.group == group), fileLogger)
        end
        push!(loggers, logger)
    end
    return TeeLogger(global_logger(), loggers...)
end
makeLogger(log_package::Bool, lf) = makeLogger(log_package ? package_groups : [], lf)
