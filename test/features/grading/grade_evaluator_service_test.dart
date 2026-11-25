import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/services/grade_evaluator_service.dart';

void main() {
  const service = GradeEvaluatorService();

  group('GradeEvaluatorService.evaluateNormalGrade', () {
    test('evaluates standard 0-4 scale with strict non-rounded cutoffs', () {
      const rules = GradingScaleConfig.defaultZeroToFourRules;

      expect(service.evaluateNormalGrade(totalScore: 100.0, rules: rules), '4');
      expect(service.evaluateNormalGrade(totalScore: 80.0, rules: rules), '4');
      expect(
        service.evaluateNormalGrade(totalScore: 79.99, rules: rules),
        '3.5',
      );
      expect(
        service.evaluateNormalGrade(totalScore: 75.0, rules: rules),
        '3.5',
      );
      expect(service.evaluateNormalGrade(totalScore: 74.99, rules: rules), '3');
      expect(service.evaluateNormalGrade(totalScore: 70.0, rules: rules), '3');
      expect(
        service.evaluateNormalGrade(totalScore: 65.0, rules: rules),
        '2.5',
      );
      expect(service.evaluateNormalGrade(totalScore: 60.0, rules: rules), '2');
      expect(
        service.evaluateNormalGrade(totalScore: 55.0, rules: rules),
        '1.5',
      );
      expect(service.evaluateNormalGrade(totalScore: 50.0, rules: rules), '1');
      expect(service.evaluateNormalGrade(totalScore: 49.99, rules: rules), '0');
      expect(service.evaluateNormalGrade(totalScore: 0.0, rules: rules), '0');
    });

    test('evaluates standard A-F scale accurately', () {
      const rules = GradingScaleConfig.defaultAToFRules;

      expect(service.evaluateNormalGrade(totalScore: 80.0, rules: rules), 'A');
      expect(
        service.evaluateNormalGrade(totalScore: 79.99, rules: rules),
        'B+',
      );
      expect(service.evaluateNormalGrade(totalScore: 75.0, rules: rules), 'B+');
      expect(service.evaluateNormalGrade(totalScore: 50.0, rules: rules), 'D');
      expect(service.evaluateNormalGrade(totalScore: 49.99, rules: rules), 'F');
      expect(service.evaluateNormalGrade(totalScore: 0.0, rules: rules), 'F');
    });

    test('handles unsorted custom rules with decimal thresholds', () {
      const unsortedCustomRules = <GradingRuleTier>[
        GradingRuleTier(grade: 'ผ่าน', minScore: 59.5),
        GradingRuleTier(grade: 'ดีเยี่ยม', minScore: 85.25),
        GradingRuleTier(grade: 'ไม่ผ่าน', minScore: 0),
      ];

      expect(
        service.evaluateNormalGrade(
          totalScore: 85.25,
          rules: unsortedCustomRules,
        ),
        'ดีเยี่ยม',
      );
      expect(
        service.evaluateNormalGrade(
          totalScore: 85.24,
          rules: unsortedCustomRules,
        ),
        'ผ่าน',
      );
      expect(
        service.evaluateNormalGrade(
          totalScore: 59.49,
          rules: unsortedCustomRules,
        ),
        'ไม่ผ่าน',
      );
    });

    test('returns dash when rules are empty or score is below all tiers', () {
      expect(
        service.evaluateNormalGrade(
          totalScore: 80.0,
          rules: const <GradingRuleTier>[],
        ),
        '-',
      );
      expect(
        service.evaluateNormalGrade(
          totalScore: 40.0,
          rules: const <GradingRuleTier>[
            GradingRuleTier(grade: 'ผ่าน', minScore: 50),
          ],
        ),
        '-',
      );
    });
  });

  group('GradeEvaluatorService.resolveDisplayedGrade', () {
    test('prioritizes explicit specialGradeOverride over evaluatedGrade', () {
      expect(
        service.resolveDisplayedGrade(
          evaluatedGrade: '3.5',
          specialGradeOverride: 'ร',
        ),
        'ร',
      );
      expect(
        service.resolveDisplayedGrade(
          evaluatedGrade: '4',
          specialGradeOverride: 'มส',
        ),
        'มส',
      );
    });

    test('falls back to evaluatedGrade when override is null or blank', () {
      expect(
        service.resolveDisplayedGrade(
          evaluatedGrade: '3.5',
          specialGradeOverride: null,
        ),
        '3.5',
      );
      expect(
        service.resolveDisplayedGrade(
          evaluatedGrade: '2',
          specialGradeOverride: '   ',
        ),
        '2',
      );
    });
  });

  group('GradeEvaluatorService.validateGradingRules', () {
    test('accepts standard presets', () {
      expect(
        service.validateGradingRules(GradingScaleConfig.defaultZeroToFourRules),
        isNull,
      );
      expect(
        service.validateGradingRules(GradingScaleConfig.defaultAToFRules),
        isNull,
      );
    });

    test('rejects empty, blank grade, negative score, and duplicates', () {
      expect(service.validateGradingRules(const <GradingRuleTier>[]), isNotNull);
      expect(
        service.validateGradingRules(const <GradingRuleTier>[
          GradingRuleTier(grade: '   ', minScore: 50),
        ]),
        isNotNull,
      );
      expect(
        service.validateGradingRules(const <GradingRuleTier>[
          GradingRuleTier(grade: '0', minScore: -1),
        ]),
        isNotNull,
      );
      expect(
        service.validateGradingRules(const <GradingRuleTier>[
          GradingRuleTier(grade: '4', minScore: 80),
          GradingRuleTier(grade: '3.5', minScore: 80),
        ]),
        isNotNull,
      );
      expect(
        service.validateGradingRules(const <GradingRuleTier>[
          GradingRuleTier(grade: '4', minScore: 80),
          GradingRuleTier(grade: '4', minScore: 75),
        ]),
        isNotNull,
      );
    });
  });
}
