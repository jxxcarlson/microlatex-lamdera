module Evergreen.V296.Parser.Expr exposing (..)

import Evergreen.V296.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V296.Parser.Meta.Meta
    | Text String Evergreen.V296.Parser.Meta.Meta
    | Verbatim String String Evergreen.V296.Parser.Meta.Meta
