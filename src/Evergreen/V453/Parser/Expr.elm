module Evergreen.V453.Parser.Expr exposing (..)

import Evergreen.V453.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V453.Parser.Meta.Meta
    | Text String Evergreen.V453.Parser.Meta.Meta
    | Verbatim String String Evergreen.V453.Parser.Meta.Meta
