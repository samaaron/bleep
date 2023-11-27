import * as ohm from "../../../vendor/ohm";

// valid tweaks, used for error checking
const validTweaks = {
  "SAW-OSC": ["detune", "pitch"],
  "SIN-OSC": ["detune", "pitch"],
  "SQR-OSC": ["detune", "pitch"],
  "TRI-OSC": ["detune", "pitch"],
  "PULSE-OSC": ["detune", "pitch", "pulsewidth"],
  LFO: ["pitch", "phase"],
  LPF: ["cutoff", "resonance"],
  HPF: ["cutoff", "resonance"],
  VCA: ["level"],
  SHAPER: ["fuzz"],
  ADSR: ["attack", "decay", "sustain", "release", "level"],
  DECAY: ["attack", "decay", "level"],
  PAN: ["angle"],
  DELAY: ["lag"],
};

// valid patch inputs, used for error checking
const validPatchInputs = {
  AUDIO: ["in"],
  "SAW-OSC": ["pitchCV"],
  "SIN-OSC": ["pitchCV"],
  "SQR-OSC": ["pitchCV"],
  "TRI-OSC": ["pitchCV"],
  "PULSE-OSC": ["pitchCV", "pulsewidthCV"],
  LPF: ["in", "cutoffCV"],
  HPF: ["in", "cutoffCV"],
  VCA: ["in", "levelCV"],
  SHAPER: ["in"],
  PAN: ["in", "angleCV"],
  DELAY: ["in", "lagCV"],
};

// valid patch outputs - pointless at the moment but in future modules may have more than one output

const validPatchOutputs = {
  "SAW-OSC": ["out"],
  "SIN-OSC": ["out"],
  "SQR-OSC": ["out"],
  "TRI-OSC": ["out"],
  "PULSE-OSC": ["out"],
  LFO: ["out"],
  NOISE: ["out"],
  LPF: ["out"],
  HPF: ["out"],
  VCA: ["out"],
  SHAPER: ["out"],
  ADSR: ["out"],
  DECAY: ["out"],
  PAN: ["out"],
  DELAY: ["out"],
};

// ------------------------------------------------------------
// make the grammar
// ------------------------------------------------------------

// ------------------------------------------------------------
// we got some json by parsing the grammar, but we need to put it into
// a standard structure that can describe the synth (and could be used to
// describe other kinds of synth)
// ------------------------------------------------------------

export default class Grammar {
  #grammar_source;
  #grammar;
  #semantics;

  constructor() {
    const grammar_source = String.raw`
      Synth {

  Graph = Synthblock Statement+

  Parameter = "@param" paramname Paramtype Mutable Paramstep Minval Maxval Defaultval Docstring "@end"

  Synthblock = "@synth" shortname Longname Type Author Version Docstring "@end"

  shortname = letter (letter | "-")+

  paramname = letter (alnum | "_")+

  Mutable (a yes or no value)
  = "mutable" ":" yesno

  yesno = "yes" | "no"

  Paramtype (a parameter type)
  = "type" ":" validtype

  Paramstep (a parameter step value)
  = "step" ":" number

  validtype (a valid type)
  = "float" | "int"

  Longname (a long name)
  = "longname" ":" string

  Type (a patch type)
  = "type" ":" Patchtype

  Patchtype (a synth or effect type)
  = "synth" | "effect"

  Minval (a minimum value)
  = "min" ":" number

  Maxval (a maximum value)
  = "max" ":" number

  Defaultval (a default value)
  = "default" ":" number

  Author (an author)
  = "author" ":" string

  Version (a version string)
  = "version" ":" versionstring

  Docstring (a documentation string)
  = "doc" ":" string

  versionstring (a version string)
  = (alnum | "." | "-" | " ")+

  string (a string)
  = letter (alnum | "." | "," | "-" | " " | "(" | ")" )*

  quote (a quote)
  = "\""

  Statement = comment
  | Parameter
  | Patch
  | Tweak
  | Declaration

  Patch = patchoutput "->" (patchinput | audio)

  patchoutput = varname "." outputparam

  patchinput = varname "." inputparam

  inputparam = "in" | "levelCV" | "pitchCV" | "cutoffCV" | "pulsewidthCV" | "angleCV" | "lagCV"

  outputparam = "out"

  audio = "audio.in"

  comment (a comment)
  = "#" commentchar*

  commentchar = alnum | "." | "+" | "-" | "/" | "*" | "." | ":" | blank

  Tweak = tweakable "=" Exp

  Declaration = module ":" varname

  module = "SAW-OSC"
  | "SIN-OSC"
  | "SQR-OSC"
  | "TRI-OSC"
  | "PULSE-OSC"
  | "LFO"
  | "NOISE"
  | "LPF"
  | "HPF"
  | "VCA"
  | "SHAPER"
  | "ADSR"
  | "DECAY"
  | "PAN"
  | "DELAY"

  Exp
    = AddExp

  AddExp
    = AddExp "+" MulExp  -- add
  | AddExp "-" MulExp  -- subtract
  | MulExp

  MulExp
    = MulExp "*" ExpExp -- times
    | MulExp "/" ExpExp -- divide
    | ExpExp

  ExpExp
    = "(" AddExp ")" -- paren
    | "-" ExpExp -- neg
    | Function
    | number
    | control

  Function
    = "map" "(" AddExp "," number "," number ")" -- map
    | "random" "(" number "," number ")" -- random
    | "exp" "(" AddExp ")" -- exp
    | "log" "(" AddExp ")" -- log

  control (a control parameter)
  = "param" "." letter (alnum | "_")+

  tweakable
  = varname "." parameter

  parameter = "pitch" | "detune" | "level" | "lag" | "phase" | "angle" | "cutoff" | "resonance" | "attack" | "decay" | "sustain" | "release" | "fuzz" | "pulsewidth"

  varname (a module name)
  = lower alnum*

  number (a number)
  = floatingpoint | integer

  floatingpoint = "-"? digit+ "." digit+

  integer = "-"? digit+

  blank = " "

}
      `;

    this.#grammar_source = grammar_source;
    this.#grammar = ohm.grammar(grammar_source);
    this.#semantics = this.#grammar.createSemantics();
    let modules;
    let patches;
    let tweaks;
    let controls;

    // add actions to the semantics, in order to return a JSON structure that represents a synth
    this.#semantics.addOperation("interpret", {
      Graph(a, b) {
        modules = new Map();
        patches = new Map();
        tweaks = [];
        // always have access to pitch and level
        controls = ["pitch", "level"];
        return `{"synth":{${a.interpret()}},"statements":[${"".concat(
          b.children.map((z) => z.interpret())
        )}]}`;
      },
      Synthblock(a, b, c, d, e, f, g, h) {
        return `${b.interpret()},${c.interpret()},${d.interpret()},${e.interpret()},${f.interpret()},${g.interpret()}`;
      },
      Parameter(a, b, c, d, e, f, g, h, i, j) {
        return `{"param":{${b.interpret()},${c.interpret()},${d.interpret()},${e.interpret()},${f.interpret()},${g.interpret()},${h.interpret()},${i.interpret()}}}`;
      },
      Paramtype(a, b, c) {
        return `"type":"${c.interpret()}"`;
      },
      Mutable(a, b, c) {
        return `"mutable":"${c.sourceString}"`;
      },
      validtype(a) {
        return a.sourceString;
      },
      Paramstep(a, b, c) {
        return `"step":${c.interpret()}`;
      },
      Minval(a, b, c) {
        return `"min":${c.interpret()}`;
      },
      Maxval(a, b, c) {
        return `"max":${c.interpret()}`;
      },
      Defaultval(a, b, c) {
        return `"default":${c.interpret()}`;
      },
      paramname(a, b) {
        let controlname = a.sourceString + b.sourceString;
        controls.push(controlname);
        return `"name":"${controlname}"`;
      },
      shortname(a, b) {
        return `"shortname":"${a.sourceString}${b.sourceString}"`;
      },
      Longname(a, b, c) {
        return `"longname":${c.interpret()}`;
      },
      Type(a, b, c) {
        return `"type":"${c.interpret()}"`;
      },
      Patchtype(a) {
        return a.sourceString;
      },
      Author(a, b, c) {
        return `"author":${c.interpret()}`;
      },
      Version(a, b, c) {
        return `"version":${c.interpret()}`;
      },
      Docstring(a, b, c) {
        return `"doc":${c.interpret()}`;
      },
      string(a, b) {
        return `"${a.sourceString}${b.sourceString}"`;
      },
      versionstring(a) {
        return `"${a.sourceString}"`;
      },
      inputparam(a) {
        return a.sourceString;
      },
      outputparam(a) {
        return a.sourceString;
      },
      Patch(a, b, c) {
        const from = a.interpret();
        const to = c.interpret();
        if (patches.get(from) === to)
          throwError(`duplicate patch connection`, this.#grammar_source);
        const fromObj = JSON.parse(from);
        const toObj = JSON.parse(to);
        if (fromObj.id === toObj.id)
          throwError(`cannot patch a module into itself`, this.#grammar_source);
        patches.set(from, to);
        return `{"patch":{"from":${from},"to":${to}}}`;
      },
      patchoutput(a, b, c) {
        const id = a.interpret();
        const param = c.interpret();
        if (id != "audio") {
          // audio out
          if (!modules.has(id))
            throwError(
              `a module called "${id}" has not been defined"`,
              this.#grammar_source
            );
          const type = modules.get(id);
          if (!validPatchOutputs[type].includes(param))
            throwError(
              `cannot patch the parameter "${param}" of module "${id}"`,
              this.#grammar_source
            );
        }
        return `{"id":"${id}","param":"${param}"}`;
      },
      patchinput(a, b, c) {
        const id = a.interpret();
        const param = c.interpret();
        if (id != "audio") {
          // audio in
          if (!modules.has(id))
            throwError(
              `a module called "${id}" has not been defined`,
              this.#grammar_source
            );
          const type = modules.get(id);
          if (!validPatchInputs[type].includes(param))
            throwError(
              `cannot patch the parameter "${param}" of module "${id}"`,
              this.#grammar_source
            );
        }
        return `{"id":"${id}","param":"${param}"}`;
      },
      Tweak(a, b, c) {
        let tweakedParam = a.interpret();
        let obj = JSON.parse(`{${tweakedParam}}`);
        let twk = `${obj.id}.${obj.param}`;
        // check that this is a valid tweak
        let type = modules.get(obj.id);
        if (!validTweaks[type].includes(obj.param))
          throwError(
            `cannot set the parameter "${obj.param}" of module "${obj.id}"`,
            this.#grammar_source
          );
        if (tweaks.includes(twk))
          throwError(
            `you cannot set the value of ${twk} more than once`,
            this.#grammar_source
          );
        tweaks.push(twk);
        return `{"tweak":{${tweakedParam},${c.interpret()}}}`;
      },
      comment(a, b) {
        return `{"comment":"${b.sourceString.trim()}"}`;
      },
      tweakable(a, b, c) {
        let id = a.interpret();
        if (!modules.has(id))
          throwError(
            `the module "${id}" has not been defined`,
            this.#grammar_source
          );
        return `"id":"${id}", "param":"${c.sourceString}"`;
      },
      varname(a, b) {
        return a.sourceString + b.sourceString;
      },
      Declaration(a, b, c) {
        const type = a.interpret();
        const id = c.interpret();
        if (modules.has(id))
          throwError(
            `module "${id}" has already been defined`,
            this.#grammar_source
          );
        modules.set(id, type);
        return `{"module":{"type":"${type}","id":"${id}"}}`;
      },
      module(a) {
        return a.sourceString;
      },
      Exp(a) {
        return `"expression":"${a.interpret()}"`;
      },
      AddExp(a) {
        return a.interpret();
      },
      AddExp_add(a, b, c) {
        return `${a.interpret()}+${c.interpret()}`;
      },
      AddExp_subtract(a, b, c) {
        return `${a.interpret()}-${c.interpret()}`;
      },
      MulExp(a) {
        return a.interpret();
      },
      MulExp_times(a, b, c) {
        return `${a.interpret()}*${c.interpret()}`;
      },
      MulExp_divide(a, b, c) {
        return `${a.interpret()}/${c.interpret()}`;
      },
      ExpExp_paren(a, b, c) {
        return `(${b.interpret()})`;
      },
      ExpExp_neg(a, b) {
        return `-${b.interpret()}`;
      },
      ExpExp(a) {
        return a.interpret();
      },
      Function_map(a, b, c, d, e, f, g, h) {
        return `map(${c.interpret()},${e.interpret()},${g.interpret()})`;
      },
      Function_random(a, b, c, d, e, f) {
        return `random(${c.interpret()},${e.interpret()})`;
      },
      Function_exp(a, b, c, d) {
        return `exp(${c.interpret()})`;
      },
      Function_log(a, b, c, d) {
        return `log(${c.interpret()})`;
      },
      number(a) {
        return a.interpret();
      },
      integer(a, b) {
        const sign = a.sourceString == "-" ? -1 : 1;
        return sign * parseInt(b.sourceString);
      },
      floatingpoint(a, b, c, d) {
        const sign = a.sourceString == "-" ? -1 : 1;
        return sign * parseFloat(b.sourceString + "." + d.sourceString);
      },
      control(a, b, c, d) {
        let ctrl = c.sourceString + d.sourceString;
        if (!controls.includes(ctrl))
          throwError(
            `control parameter "${ctrl}" has not been defined`,
            this.#grammar_source
          );
        return `param.${ctrl}`;
      },
    });
  }

  parse(synthdef) {
    let result = this.#grammar.match(synthdef + "\n");
    let adapter = this.#semantics(result);
    return adapter.interpret();
  }

  parseStandard(synthdef) {
    let json = this.parse(synthdef);
    return this.convertToStandardJSON(json);
  }

  convertToPostfix(expression) {
    // shunting yard algorithm with functions
    const ops = { "+": 1, "-": 1, "*": 2, "/": 2 };
    const funcs = { log: 1, exp: 1, random: 1, map: 1 };
    // split the expression
    const tokens = expression.split(/([\*\+\-\/\,\(\)])/g).filter((x) => x);
    // deal with unary minus
    // is there a minus at the start?
    if (tokens.length > 1 && tokens[0] == "-" && this.#isNumber(tokens[1])) {
      tokens.shift();
      let n = parseFloat(tokens.shift());
      tokens.unshift(`${-1 * n}`);
    }
    // is there a minus after a bracket or other operator?
    if (tokens.length > 2) {
      for (let i = 1; i < tokens.length - 1; i++) {
        let pre = tokens[i - 1];
        let mid = tokens[i];
        let post = tokens[i + 1];
        if (mid == "-" && this.#isNumber(post) && (pre == "(" || pre in ops)) {
          let n = -1 * parseFloat(post);
          tokens[i + 1] = `${n}`;
          tokens.splice(i, 1);
        }
      }
    }
    let top = (s) => s[s.length - 1];
    let stack = [];
    let result = [];
    for (let t of tokens) {
      if (this.#isNumber(t) || this.#isIdentifier(t)) {
        result.push(t);
      } else if (t == "(") {
        stack.push(t);
      } else if (t == ")") {
        while (top(stack) != "(") {
          let current = stack.pop();
          result.push(current);
        }
        stack.pop();
        if (stack.length > 0) {
          if (top(stack) in funcs) {
            let current = stack.pop();
            result.push(current);
          }
        }
      } else if (t in funcs) {
        stack.push(t);
      } else if (t == ",") {
        while (top(stack) != "(") {
          let current = stack.pop();
          result.push(current);
        }
      } else if (t in ops) {
        // deal with unary minus
        while (
          stack.length > 0 &&
          top(stack) in ops &&
          ops[top(stack)] >= ops[t]
        ) {
          let current = stack.pop();
          result.push(current);
        }
        stack.push(t);
      }
    }
    while (stack.length > 0) {
      let current = stack.pop();
      if (current != ",") {
        result.push(current);
      }
    }
    return result;
  }
  convertToStandardJSON(json) {
    // we need to put the JSON from the grammar into a standard format
    const tree = JSON.parse(json);
    var std = {};
    std.longname = tree.synth.longname;
    std.shortname = tree.synth.shortname;
    std.version = tree.synth.version;
    std.author = tree.synth.author;
    std.doc = tree.synth.doc;
    std.prototype = "builder";
    std.modules = [];
    // filter the statements into the right structures
    const statements = tree.statements;
    for (let i = 0; i < statements.length; i++) {
      let obj = statements[i];
      if (obj.module) {
        std.modules.push(obj.module);
      } else if (obj.patch) {
        // find the type of the from id
        let found = std.modules.find((a) => a.id === obj.patch.from.id);
        const type = found.type;
        // we treat envelopes differently for efficiency reasons
        if (type === "ADSR" || type === "DECAY") {
          if (!std.envelopes) {
            std.envelopes = [];
          }
          std.envelopes.push(obj.patch);
        } else {
          if (!std.patches) {
            std.patches = [];
          }
          std.patches.push(obj.patch);
        }
      } else if (obj.param) {
        if (!std.parameters) {
          std.parameters = [];
        }
        std.parameters.push(obj.param);
      } else if (obj.tweak) {
        if (!std.tweaks) {
          std.tweaks = [];
        }
        var mytweak = {};
        mytweak.id = obj.tweak.id;
        mytweak.param = obj.tweak.param;
        mytweak.expression = this.convertToPostfix(obj.tweak.expression);
        std.tweaks.push(mytweak);
      }
    }
    return JSON.stringify(std);
  }

  #isNumber(t) {
    return !isNaN(parseFloat(t)) && isFinite(t);
  }

  #isIdentifier(t) {
    return typeof t === "string" && t.startsWith("param.");
  }
}
