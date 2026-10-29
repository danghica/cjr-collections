import unittest,csv,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class BenchmarkHistoryTests(unittest.TestCase):
    def test_historical_benchmark_partitions_preserve_provenance_until_rerun(self):
        historical = ROOT / 'paper/benchmark-history'
        with (historical / 'raw.csv').open() as stream:
            original = list(csv.DictReader(stream))
        original_metadata = json.loads((historical / 'metadata.json').read_text())
        key = lambda row: tuple(sorted(row.items()))
        for name, prefix in [('list', 'list_'), ('array', 'array_'),
                             ('array_list', 'arraylist_'), ('hash_map', 'hashmap_')]:
            output = ROOT / 'example' / name / 'benchmark/results'
            with (output / 'raw.csv').open() as stream:
                partition = list(csv.DictReader(stream))
            data = json.loads((output / 'metadata.json').read_text())
            self.assertEqual(data['samples'], len(partition))
            if data.get('historical'):
                self.assertEqual(data['date_utc'], original_metadata['date_utc'])
                self.assertEqual(data['sources'], original_metadata['sources'])
                expected = [row for row in original if row['case'].startswith(prefix)]
                self.assertCountEqual([key(row) for row in partition], [key(row) for row in expected])
            else:
                self.assertGreater(data['date_utc'], original_metadata['date_utc'])
                self.assertTrue(data['benchmark_sources'])
                self.assertTrue(data['harness_sources'])

