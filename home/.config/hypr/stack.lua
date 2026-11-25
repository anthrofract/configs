-- Groups the tiled windows on a workspace, joining an existing group if there is one
return function(workspace, anchor)
  local windows, group = {}, nil
  for _, window in ipairs(hl.get_workspace_windows(workspace)) do
    if not window.floating then
      table.insert(windows, window)
      group = group or window.group
    end
  end
  if #windows < 2 then
    return
  end

  if not group then
    anchor = anchor or windows[1]
    hl.dispatch(hl.dsp.group.toggle({ window = anchor }))
    group = anchor.group
  end

  for _, window in ipairs(windows) do
    if not window.group then
      group:add(window)
    end
  end
end
