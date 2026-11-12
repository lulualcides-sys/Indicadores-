from pathlib import Path
import re,unittest
HERE=Path(__file__).resolve().parent
SOURCE=(HERE/"Nexus_Visual_Unificado_TP_Painel_Som.mq5").read_text(encoding="utf-8")
class UniversalSignals(unittest.TestCase):
    def test_exact_ten_supported_models(self):
        self.assertEqual(SOURCE.count("#property tester_indicator"),10)
        self.assertEqual(len(re.findall(r'case NX_\w+\s*:\s*return "NexusBase',SOURCE)),10)
    def test_two_signal_buffers(self):
        self.assertIn('CopyBuffer(g_handle,0,0,count,srcBuy)',SOURCE)
        self.assertIn('CopyBuffer(g_handle,1,0,count,srcSell)',SOURCE)
    def test_entry_only_next_open(self):
        self.assertIn('const double nextOpen=open[i];',SOURCE)
        self.assertIn('entryPending=true;',SOURCE)
        self.assertIn('if(i==0) break;',SOURCE)
    def test_one_signal_active(self):
        self.assertIn('if(t.active || entryPending) continue;',SOURCE)
        self.assertIn('if(InpOnePerDirection && dir==lastDirection) continue;',SOURCE)
        self.assertIn('lastEntryIndex-i<InpMinBarsBetweenSignals',SOURCE)
    def test_tp_sl_same_bar_priority(self):
        self.assertLess(SOURCE.index('if(stopHit)'),SOURCE.index('else if(targetHit)'))
        self.assertIn('t.dir*(exitPrice-t.entry)/_Point',SOURCE)
    def test_panel_and_sound(self):
        for txt in ('GREEN  ','RED  ','TOTAL  ','PlaySound(InpSoundFile)',
                    'if(i==0 && realNewBar && g_lastSoundEntry!=time[i])'):
            self.assertIn(txt,SOURCE)
    def test_m1_special(self):
        self.assertIn('NX_VECTOR_M1 && _Period!=PERIOD_M1',SOURCE)
    def test_no_execution_or_external_io(self):
        for txt in ('OrderSend(', 'WebRequest(', '#import "'):
            self.assertNotIn(txt,SOURCE)
    def test_braces(self):
        self.assertEqual(SOURCE.count('{'),SOURCE.count('}'))
if __name__=='__main__':unittest.main()
