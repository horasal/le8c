%{
import structs/[ArrayList, Stack, HashMap]
import io/[Reader, Writer]

import [Node, Error]

Greg : class {
	lineNumber = 0
	rowNumber = 0

	fileName: String
	reader: Reader
	writer: Writer = stdout

	stack := Stack<Node> new()
	header := ArrayList<Header> new()
	footer := Footer new()

	yyinput: inline func -> Char {
		c := reader read()
		if(c == '\n' || c == '\r') lineNumber += 1
		c
	}

%}
grammar=	- ( declaration | definition )+ trailer? end-of-file

declaration=	'%{' < ( !'%}' . )* > RPERCENT		{ header add(Header new(yytext)) }						#{YYACCEPT}

trailer=	'%%' < .* >				{ footer = Footer new(yytext) }					#{YYACCEPT}

definition=	s:identifier 				{ if(r := rules find(yytext) {
								stack push(r)
								Warning new("rule %s redefined\n" format(yytext)) throw()
							  } else {
							  	rules add(yytext, 1)
								stack push(rules last())
							  } 
							}
			EQUAL expression		{ e := stack pop()
							  stack peek() as Rule setExpr(e) }
			SEMICOLON?											#{YYACCEPT}

expression=	sequence (BAR sequence			{ f := stack pop()
							  stack peek() as Alternate add(f) }
			    )*

sequence=	prefix (prefix				{ f := stack pop()
							  stack peek() as Sequence add(f) }
			  )*

prefix=		AND action				{ stack push(Predicate new(yytext)) }
|		AND suffix				{ stack push(PeekFor new(pop())) }
|		NOT suffix				{ stack push(PeekNot new(pop())) }
|		    suffix

suffix=		primary (QUESTION			{ stack push(Query new(pop())) }
                        | STAR			        { stack push(Star new(pop())) }
			| PLUS			        { stack push(Plus new(pop())) }
			)?

primary=	(
                identifier				{ stack push(Variable new(yytext)); }
			COLON identifier !EQUAL		{ name := Name new(rules find(yytext,0))
							  name variable= stack pop()
							  stack push(name) }
|		identifier !EQUAL			{ stack push(Name new(rules find(yytext,0))) }
|		OPEN expression CLOSE
|		literal					{ stack push(String new(yytext)) }
|		class					{ stack push(Class new(yytext)) }
|		DOT					{ stack push(Dot new()) }
|		action					{ stack push(Action new(yytext)) }
|		BEGIN					{ stack push(Predicate new("YY_BEGIN")) }
|		END					{ stack push(Predicate new("YY_END")) }
                ) (errblock { stack peek() errorBlock = yytext})?

# Lexical syntax

identifier=	< [-a-zA-Z_][-a-zA-Z_0-9]* > -

literal=	['] < ( !['] char )* > ['] -
|		["] < ( !["] char )* > ["] -

class=		'[' < ( !']' range )* > ']' -

range=		char '-' char | char

char=		'\\' [abefnrtv'"\[\]\\]
|		'\\' [0-3][0-7][0-7]
|		'\\' [0-7][0-7]?
|		!'\\' .


errblock=       '~{' < braces* > '}' -
action=		'{' < braces* > '}' -

braces=		'{' (!'}' .)* '}'
|		!'}' .

EQUAL=		'=' -
COLON=		':' -
SEMICOLON=	';' -
BAR=		'|' -
AND=		'&' -
NOT=		'!' -
QUESTION=	'?' -
STAR=		'*' -
PLUS=		'+' -
OPEN=		'(' -
CLOSE=		')' -
DOT=		'.' -
BEGIN=		'<' -
END=		'>' -
RPERCENT=	'%}' -

-=		(space | single-line-comment | quoted-comment)*
space=		' ' | '\t' | end-of-line
single-line-comment= ('#' | '//') till-end-of-line
quoted-comment= "/*" (!"*/" .)* "*/"
till-end-of-line=	(!end-of-line .)* end-of-line
end-of-line=	'\r\n' | '\n' | '\r'
end-of-file=	!.

%%
	compile: func {
		for(h in header){ writer write(h compile()). nl() }
		writer nl()
		// TODO copile rule

		// compile footer
		writer write(footer compile()). nl()
	}
}

main : func(args: ArrayList<String>) -> Int{
	g := Greg new()
	g parse()
	g compile()
	0
}
