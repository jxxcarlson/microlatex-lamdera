module Evergreen.V296.Compiler.DifferentialParser exposing (..)

import Evergreen.V296.Compiler.AbstractDifferentialParser
import Evergreen.V296.Compiler.Acc
import Evergreen.V296.Parser.Block
import Evergreen.V296.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V296.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V296.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V296.Parser.Block.ExpressionBlock) Evergreen.V296.Compiler.Acc.Accumulator
