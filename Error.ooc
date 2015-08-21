import os/Terminal

Message : abstract class{
	message: String
	init: func(=message)
	throw: abstract func(exit: Bool)
}

Warning: class extends Message {
	init: func(=message)
	throw: func(exit: Bool = false){
		Terminal setFgColor(Color yellow)
		"[Warning] %s" println(message)
		Terminal reset()
		if(exit) exit(1)
	}
}

Error: class extends Message {
	init: func(=message)
	throw: func(exit: Bool = true){
		Terminal setFgColor(Color red)
		"[ Error ] %s" println(message)
		Terminal reset()
		if(exit) exit(1)
	}
}
