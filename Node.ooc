RuleManager: class{
	rules:= ArrayList<Rule> new()
	currentrule := 0

	add: func(name: String, defined: Bool) -> Rule {
		r := Rule new(name, rules size, defined)
		rules add(r)
		r
	}

	find: func(name: String, defined: Bool) -> Rule {
		rname := name map(|x| x == '-' ? '_' : x)
		for(r in rules){
			if(r name == rname) return r
		}
		return add(name, defined)
	}

	begin: func(count: Int){ currentrule = count }
}

Node: abstract class

Rule: class extends Node {
	name: String
	variables := ArrayList<Variable> new() 
	expression : Node
	id, flags: Int

	init: func(=name, =id, defined: Bool){
		r flags = defined ? RuleUsed : 0
	}

	addVariable: func(name: String) -> Node {
		for(v in variables){
			if(v name == name) return v
		}
		v := Variable new(name)
		variables add(v)
		v
	}
}

Variable: class extends Node {
	name: String
	value: Node
	offset: Int

	init: func(=name)
}

Name: class extends Node {
	rule, variable: Node

	init: func(=rule) {
		variable = null
		rule flags = rule flags | RuleUsed
	}
}

Dot: class extends Node { init: func }

Character: class extends Node {
	value: string
	init: func(=value)
}

String: class extends Node {
	value; String
	init: func(=value)
}

Class: class extends Node {
	value := ArrayList<UInt8> new()
	init: func(text: String){ text each(|x| value add(x as UInt8)) }
}

Action: class extends Node {
	text: String
	name: String
	rule: Node

	init: func(=text, actionCount: Int, =rule){
		name = "_%d_%s" format(actionCount, rule name)	
		for(i in 0..text size - 1){
			if(text[i] == '$' && text[i+1] == '$'){
				text[i] = 'y'
				text[i+1] = 'y'
			}
		}
	}
}

Predicate: class extends Node {
	text: String
	init: func(=text)
}

Alternate: class extends Node {
	value := ArrayList<Node> new()
	init: func(e: Node){
		if(e instanceOf?(Alternate)){ 
			this = e
			return
		}
		value add(e)
	}
}

Sequence: class extends Node {
	value := ArrayList<Node> new()
	init: func(e: Node) {
		if(e instanceOf?(Sequence)){ 
			this = e
			return
		}
		value add(e)
	}
	append: func(e: Node) { value add(e) }
}

PeekFor: class extends Node {
	element: Node
	init: func(=element)
}

PeekNot: class extends Node {
	element: Node
	init: func(=element)
}

Query: class extends Node {
	element: Node
	init: func(=element)
}

Star: class extends Node {
	element: Node
	init: func(=element)
}

Plus: class extends Node {
	element: Node
	init: func(=element)
}

Any: class extends Node
