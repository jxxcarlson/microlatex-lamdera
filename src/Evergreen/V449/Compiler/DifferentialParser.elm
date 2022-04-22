module Evergreen.V449.Compiler.DifferentialParser exposing (..)

import Evergreen.V449.Compiler.AbstractDifferentialParser
import Evergreen.V449.Compiler.Acc
import Evergreen.V449.Parser.Block
import Evergreen.V449.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V449.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V449.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V449.Parser.Block.ExpressionBlock) Evergreen.V449.Compiler.Acc.Accumulator
