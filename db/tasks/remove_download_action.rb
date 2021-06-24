Action.find_by(name: 'download').delete unless Action.find_by(name: 'download').nil?
