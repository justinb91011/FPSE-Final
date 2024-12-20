// Button.res
@react.component
let make = (~className=?, ~onClick=?, ~children) => {
  let defaultClassName =
    "inline-block px-6 py-2.5 bg-yellow-400 text-black font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"

  // Determine the final className
  let finalClassName = switch className {
    | Some(cn) => cn
    | None => defaultClassName
  }

  <button
    className=finalClassName
    onClick=?onClick // Correctly handle the optional onClick
  >
    children
  </button>
}