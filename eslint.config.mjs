import reactHooks from "eslint-plugin-react-hooks";

export default [
  {
    // Lint the compiled ReScript output — ESLint understands standard JS/MJS.
    //
    // Value: catches Rules of Hooks violations that the ReScript compiler
    // doesn't enforce — conditional hook calls, hooks inside loops, hooks
    // called outside components. These bugs are hard to debug at runtime.
    //
    // Not valuable here: exhaustive-deps and immutability rules are designed
    // for hand-written code where you can add eslint-disable comments.
    // Compiled .res.mjs files are overwritten on every build — you can't
    // annotate generated lines. The signal-to-noise ratio on those rules
    // is too low for compiled output.
    files: ["src/**/*.res.mjs"],
    plugins: {
      "react-hooks": reactHooks,
    },
    rules: {
      // The rule that matters: catches conditional/loop/nested hook calls.
      "react-hooks/rules-of-hooks": "error",

      // Off for compiled output: false positives on stable dispatch/setState
      // refs, and no way to annotate generated files.
      "react-hooks/exhaustive-deps": "off",

      // Off for compiled output: flags valid event-handler side effects
      // (e.g., window.location.hash = ...) that are correct React code.
      "react-hooks/immutability": "off",
    },
  },
];
