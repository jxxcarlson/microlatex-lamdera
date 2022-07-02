module Evergreen.V690.Compiler.DifferentialParser exposing (..)

import Evergreen.V690.Compiler.AbstractDifferentialParser
import Evergreen.V690.Compiler.Acc
import Evergreen.V690.Parser.Block
import Evergreen.V690.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V690.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V690.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V690.Parser.Block.ExpressionBlock) Evergreen.V690.Compiler.Acc.Accumulator
