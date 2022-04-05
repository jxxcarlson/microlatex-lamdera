module Evergreen.V258.Compiler.DifferentialParser exposing (..)

import Evergreen.V258.Compiler.AbstractDifferentialParser
import Evergreen.V258.Compiler.Acc
import Evergreen.V258.Parser.Block
import Evergreen.V258.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V258.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V258.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V258.Parser.Block.ExpressionBlock) Evergreen.V258.Compiler.Acc.Accumulator
