RuleUsed      := static const 1<<0
RuleReached   := static const 1<<1

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

Node: abstract class {
	errorBlock: String
	compile: abstract func -> String
	consumesInput: abstract func -> Bool
	toString: abstract func -> String
}

Header : class extends Node {
	text: String
	init: func(=text)
	compile: func -> String { 
		"/* A recursive-descent parser generated by le8c */\n" + \
		"/* parser header */" + text
	}
	consumesInput: func -> Bool { false }
	toString: func -> String { "Header: " + text }
}

Rule: class extends Node {
	name: String
	variables := ArrayList<Variable> new() 
	expression : Node
	id, flags: Int

	init: func(=name, =id, defined: Bool){
		r flags = defined ? RuleUsed : 0
	}

	toString: func -> String { "Rule " + name }

	addVariable: func(name: String) -> Node {
		for(v in variables){
			if(v name == name) return v
		}
		v := Variable new(name)
		variables add(v)
		v
	}

	compile: func -> String {
		if(!expression) Error new("rule %s used but not defined" format(name)) throw()
		safe := expression instanceOf?(Query) || expression instanceOf?(Star)
		//ko := globalCounter()
		ret := "yyRule: func {\n"
		
	}

	consumesInput: func -> Bool {
		result := false
		if(RuleReached & flags) Warning new("possible infinite left recursion in rule %s" format(this toString())) throw()
		else {
			flags = flags | RuleReached
			result = expression consumesInput()
			flags = flags & (~RuleReached)

		}
		result
	}
}

Variable: class extends Node {
	name: String
	value: Node
	offset: Int

	init: func(=name)
	compile: func -> String
	define: func -> String {
		"%s := valTable[%d" printfln(name, offset)
	}

	toString: func -> String { "Variable " + name }
}

Name: class extends Node {
	rule, variable: Node

	init: func(=rule) {
		variable = null
		rule flags = rule flags | RuleUsed
	}
	compile: func -> String
	consumesInput: func -> Bool { rule consumesInput() }
}

Dot: class extends Node { 
	init: func
	compile: func -> String
	consumesInput: func -> Bool { true }
}

Character: class extends Node {
	value: string
	init: func(=value)
	compile: func -> String
	consumesInput: func -> Bool { value size > 0 }
}

String: class extends Node {
	value; String
	init: func(=value)
	compile: func -> String
	consumesInput: func -> Bool { value size > 0 }
}

Class: class extends Node {
	value := ArrayList<UInt8> new()
	init: func(text: String){ text each(|x| value add(x as UInt8)) }
	compile: func -> String
	consumesInput: func -> Bool { true }
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
	compile: func -> String {
		ret := ""
		ret += "yyAction%s(text: String, thunk: Thunk, data: Pointer){\n"
		for(v in rule variables){
			ret += v define()
		}
		ret += text + "\n"
		ret + "}\n"
	}
	consumesInput: func -> Bool { false }
}

Predicate: class extends Node {
	text: String
	init: func(=text)
	compile: func -> String
	consumesInput: func -> Bool { false }
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
	compile: func -> String
	consumesInput: func -> Int { 
		for(v in value) if(!v consumesInput()) return false
		true
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
	compile: func -> String
	consumesInput: func -> Int { 
		for(v in value) if(v consumesInput()) return true
		false
	}
}

PeekFor: class extends Node {
	element: Node
	init: func(=element)
	compile: func -> String
	consumesInput: func -> Int { false }
}

PeekNot: class extends Node {
	element: Node
	init: func(=element)
	compile: func -> String
	consumesInput: func -> Int { false }
}

Query: class extends Node {
	element: Node
	init: func(=element)
	compile: func -> String
	consumesInput: func -> Int { false }
}

Star: class extends Node {
	element: Node
	init: func(=element)
	compile: func -> String
	consumesInput: func -> Int { false }
}

Plus: class extends Node {
	element: Node
	init: func(=element)
	compile: func -> String
	consumesInput: func -> Int { element consumesInput() }
}
