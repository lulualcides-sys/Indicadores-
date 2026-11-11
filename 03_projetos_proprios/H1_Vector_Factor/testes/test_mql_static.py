"""Checagens estaticas de regressao. NAO substituem compilacao MetaEditor nem teste MT5."""
from pathlib import Path
import re
import unittest

BASE = Path(__file__).resolve().parents[1]
SOURCE = (BASE / "v1.20" / "H1_Vector_Factor_M1.mq5").read_text(encoding="utf-8")


class H1StaticNoRepaint(unittest.TestCase):
    def test_indicador_nao_envia_ordens(self):
        self.assertIn("#property indicator_chart_window", SOURCE)
        self.assertIn("int OnCalculate(", SOURCE)
        for token in ("OrderSend(", "CTrade(", "trade.Buy(", "trade.Sell("):
            self.assertNotIn(token, SOURCE)

    def test_duas_setas(self):
        self.assertIn("#property indicator_buffers 2", SOURCE)
        for token in ("DRAW_ARROW", "BuyBuffer", "SellBuffer", '"BUY"', '"SELL"'):
            self.assertIn(token, SOURCE)

    def test_sem_preco_da_vela_em_formacao(self):
        for token in ("open[0]", "high[0]", "low[0]", "close[0]"):
            self.assertNotIn(token, SOURCE)
        self.assertIn("BuyBuffer[0]=EMPTY_VALUE;", SOURCE)
        self.assertIn("SellBuffer[0]=EMPTY_VALUE;", SOURCE)
        self.assertIn("for(int i=oldest;i>=1;i--)", SOURCE)

    def test_setas_guardadas_por_barra_confirmada(self):
        self.assertIn("bool fullRebuild=(prev_calculated==0 || g_seenOpenBar==0);", SOURCE)
        self.assertIn("datetime lastClosedBeforePass=g_lastProcessedClosedBar;", SOURCE)
        self.assertIn("if(!fullRebuild && time[0]==g_seenOpenBar)", SOURCE)
        self.assertIn("g_lastProcessedClosedBar=time[1];", SOURCE)
        self.assertEqual(SOURCE.count("if(fullRebuild || time[i]>lastClosedBeforePass)"), 2)

    def test_canal_tem_tempo_de_disponibilidade(self):
        self.assertIn("datetime availableAt=hourStart+InpOpeningBars*60;", SOURCE)
        for token in ('Segment(id+"OPEN_HIGH",availableAt,finish', 'Segment(id+"OPEN_LOW", availableAt,finish', 'Segment(id+"MID",      availableAt,finish'):
            self.assertIn(token, SOURCE)

    def test_alvos_so_apos_confirmacao(self):
        self.assertIn("datetime labelAt=(signalTime>0 ? signalTime+60 : availableAt);", SOURCE)
        for name in ("TP1", "TP2", "TP3", "SL"):
            self.assertIn('Segment(id+"'+name+'",labelAt,finish', SOURCE)

    def test_revisao_de_historico_documentada(self):
        self.assertIn("broker-history reset", SOURCE)
        self.assertIn("broker revises OHLC", SOURCE)

    def test_elementos_visuais(self):
        for text in ('"Canal de Abertura"', '"Canal Fatiado"', '"Primeiro Ciclo"', '"AGUARDANDO PULLBACK"', '"X CANCELADO"', '"TP1 / 1R"', '"TP2 / 1.5R"', '"TP3 / 2R"'):
            self.assertIn(text, SOURCE)

    def test_integridade_lexical(self):
        self.assertEqual(SOURCE.count("{"), SOURCE.count("}"))
        self.assertEqual(SOURCE.count("("), SOURCE.count(")"))
        self.assertNotRegex(SOURCE, re.compile(r'\}\s*else\s*\{.*?\}\s*else\s+if\(', re.S))


if __name__ == "__main__":
    unittest.main()
