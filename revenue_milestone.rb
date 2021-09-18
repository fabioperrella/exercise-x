def get_milestone_days(revenues, milestones)
  total = 0
  result = []

  milestones_orig_order = {}
  milestones.each_with_index do |milestone, index|
    milestones_orig_order[milestone] = index
  end

  milestones = milestones.sort

  revenues.each_with_index do |revenue, index|
    total += revenue

    break if milestones.size == 0

    while milestones.size > 0 && total >= milestones[0]
      milestone = milestones.shift
      index_to_save = milestones_orig_order[milestone]
      result[index_to_save] = index + 1
    end
  end

  result
end

def check(expected, output)
  if expected != output
    puts "failed: #{expected} != #{output}"
  else
    puts 'ok'
  end
end

result = get_milestone_days([10, 20, 30, 40, 50, 60, 70, 80, 90, 100], [100, 200, 500])
check(result, [4, 6, 10])

result = get_milestone_days([100, 200, 300, 400, 500], [300, 800, 1000, 1400])
check(result, [2, 4, 4, 5])

result = get_milestone_days([700, 800, 600, 400, 600, 700], [3100, 2200, 800, 2100, 1000])
check(result, [5, 4, 2, 3, 2])

result = get_milestone_days([700], [100, 200, 150])
check(result, [1, 1, 1])
