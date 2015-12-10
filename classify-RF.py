#! /usr/bin/env python

import sys

import numpy as np
import numpy.random

from sklearn import metrics
from sklearn.ensemble import RandomForestClassifier, AdaBoostClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.cross_validation import StratifiedKFold
from sklearn.metrics import accuracy_score, auc, f1_score, precision_score, recall_score, roc_curve


numpy.set_printoptions(threshold=numpy.nan)

def read_dataset(fname):
    f = open(fname)
    cols = f.readline().split()
    skipcols = 1
    X = np.loadtxt(f, delimiter="\t", unpack=True, usecols=range(skipcols, len(cols)))
    y = map(lambda x: 1 if x == '1' else 0, cols[skipcols:])
    y = np.array(y)
    X_label = np.genfromtxt(fname, skip_header=1, delimiter="\t", usecols=[0], dtype='str')
    return X, y, X_label


def test():
    X, y, labels = read_dataset('tig.k10')
    print X
    print y
    print labels

def score_format(metric, score, eol='\n'):
    return '{:<15} = {:.5f}'.format(metric, score) + eol

def top_important_features(clf, feature_names, num_features=20):
    if not hasattr(clf, "feature_importances_"):
        return
    fi = clf.feature_importances_
    features = [ (f, n) for f, n in zip(fi, feature_names)]
    top = sorted(features, key=lambda f:f[0], reverse=True)[:num_features]
    return top

def sprint_features(top_features, num_features=20):
    str = ''
    for i, feature in enumerate(top_features):
        if i >= num_features: return
        str += '{}\t{:.5f}\n'.format(feature[1], feature[0])
    return str

def main():
    fname = sys.argv[1] if len(sys.argv) > 1 else 'tig.k10'
    X, y, labels = read_dataset(fname)

    classifiers = [ ('RF1',  RandomForestClassifier(n_estimators=10, n_jobs=10)),
                    ('RF2',  RandomForestClassifier(n_estimators=100, n_jobs=10)),
                    ('RF3',  RandomForestClassifier(n_estimators=1000, n_jobs=10)),
                    ('RF4', RandomForestClassifier(n_estimators=100, criterion='entropy', n_jobs=10)),
                    ('RF5', RandomForestClassifier(n_estimators=100, max_features=None, n_jobs=10)),
                    ('RF6', RandomForestClassifier(n_estimators=100, min_samples_split=5, n_jobs=10)),
                    ('RF7', RandomForestClassifier(n_estimators=100, min_weight_fraction_leaf=0.001, n_jobs=10)),
                    ('RF8', RandomForestClassifier(n_estimators=100, min_weight_fraction_leaf=0.01, n_jobs=10)),
                  ]

    for name, clf in classifiers:
        sys.stderr.write("> {}\n".format(name))
        train_scores, test_scores = [], []
        probas = None
        tests = None
        preds = None

        skf = StratifiedKFold(y, n_folds=10)
        for i, (train_index, test_index) in enumerate(skf):
            # print("  > TRAIN:", train_index, "TEST:", test_index)
            X_train, X_test = X[train_index], X[test_index]
            y_train, y_test = y[train_index], y[test_index]
            clf.fit(X_train, y_train)
            train_scores.append(clf.score(X_train, y_train))
            test_scores.append(clf.score(X_test, y_test))
            sys.stderr.write("  fold #{}: score={:.3f}\n".format(i, clf.score(X_test, y_test)))

            y_pred = clf.predict(X_test)
            preds = np.concatenate((preds, y_pred)) if preds is not None else y_pred
            tests = np.concatenate((tests, y_test)) if tests is not None else y_test

            if hasattr(clf, "predict_proba"):
                probas_ = clf.fit(X_train, y_train).predict_proba(X_test)
                probas = np.concatenate((probas, probas_)) if probas is not None else probas_

        roc_auc_core = None
        if probas is not None:
            fpr, tpr, thresholds = roc_curve(tests, probas[:, 1])
            roc_auc_score = auc(fpr, tpr)
            roc_fname = "{}.{}.ROC".format(fname, name)
            with open(roc_fname, "w") as roc_file:
                roc_file.write('\t'.join(['Threshold', 'FPR', 'TPR'])+'\n')
                for ent in zip(thresholds, fpr, tpr):
                    roc_file.write('\t'.join("{0:.5f}".format(x) for x in list(ent))+'\n')

        scores_fname = "{}.{}.scores".format(fname, name)
        ms = 'accuracy_score f1_score precision_score recall_score log_loss'.split()
        with open(scores_fname, "w") as scores_file:
            for m in ms:
                s = getattr(metrics, m)(tests, preds)
                scores_file.write(score_format(m, s))
            avg_train_score = np.mean(train_scores)
            avg_test_score = np.mean(test_scores)
            if roc_auc_score is not None:
                scores_file.write(score_format('roc_auc_score', roc_auc_score))
            scores_file.write(score_format('avg_test_score', avg_test_score))
            scores_file.write(score_format('avg_train_score', avg_train_score))
            scores_file.write('\nModel:\n{}\n\n'.format(clf))

        top_features = top_important_features(clf, labels)
        if top_features is not None:
            fea_fname = "{}.{}.features".format(fname, name)
            with open(fea_fname, "w") as fea_file:
                fea_file.write(sprint_features(top_features))

        sys.stderr.write('  test={:.5f} train={:.5f}\n\n'.format(avg_test_score, avg_train_score))



if __name__ == '__main__':
    # test()
    main()
