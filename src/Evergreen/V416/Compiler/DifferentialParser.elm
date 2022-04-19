module Evergreen.V416.Compiler.DifferentialParser exposing (..)

import Evergreen.V416.Compiler.AbstractDifferentialParser
import Evergreen.V416.Compiler.Acc
import Evergreen.V416.Parser.Block
import Evergreen.V416.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V416.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V416.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V416.Parser.Block.ExpressionBlock) Evergreen.V416.Compiler.Acc.Accumulator
