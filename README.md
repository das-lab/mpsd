# mpsd
## Research paper

We present the findings of this work in the following research paper:

Fang Yong, Zhou Xiangyu, Huang Cheng. **Effective method for detecting malicious PowerShell scripts based on hybrid features**[J]. Neurocomputing, 2021, 448: 30-39.[view](https://www.sciencedirect.com/science/article/abs/pii/S0925231221005099?via%3Dihub)

## Introduction

At present, network attacks are rampant in the Internet world, and the attack methods of hackers are changing steadily. PowerShell is a programming language based on the command line and.NET framework, with powerful functions and good compatibility. Therefore, hackers often use PowerShell malicious scripts to attack the victims in APT attacks. When these malicious PowerShell scripts are executed, hackers can control the victim’s computer or leave a backdoor on their computers. In this paper, a detection model of malicious PowerShell scripts based on hybrid features is proposed, we analyzed the differences between malicious and benign samples in text characters, functions, tokens and the nodes of the abstract syntax tree. Firstly, the script of PowerShell is embedded by FastText. Then the textual features, token features and the nodes features of PowerShell code extracted from the abstract syntax tree are added. Finally, the hybrid features of scrips will be classified by a Random Forest classifier. In the experiment, the malicious scripts are inserted into the benign scripts to weaken the features of the malicious samples in the level of abstract syntax tree nodes and tokens, which makes the scripts more complex. Even in such a complex data set, the proposed model which is based on hybrid features still achieves an accuracy of 97.76% in fivefold cross-validation. Moreover, the accuracy of this proposed model on the original scripts is 98.93%, which means that the proposed model has the ability to classify complex scripts.

## Dataset

All samples are divided into three categories:
- **malicious_pure**: The samples are malicious.
- **powershell_benign_dataset**: The samples in it are benign.

- **mixed_malicious**: All samples are malicious, and each sample is composed of a malicious sample and a random benign sample.

## Reference

If you use the dataset in a scientific publication, we would appreciate citations using this Bibtex entry:

```
@article{FANG202130,
title = {Effective method for detecting malicious PowerShell scripts based on hybrid features☆},
journal = {Neurocomputing},
volume = {448},
pages = {30-39},
year = {2021},
issn = {0925-2312},
doi = {https://doi.org/10.1016/j.neucom.2021.03.117},
url = {https://www.sciencedirect.com/science/article/pii/S0925231221005099},
author = {Yong Fang and Xiangyu Zhou and Cheng Huang},
keywords = {Powershell, Abstract syntax tree, Scripts detection, Machine learning},
abstract = {At present, network attacks are rampant in the Internet world, and the attack methods of hackers are changing steadily. PowerShell is a programming language based on the command line and.NET framework, with powerful functions and good compatibility. Therefore, hackers often use PowerShell malicious scripts to attack the victims in APT attacks. When these malicious PowerShell scripts are executed, hackers can control the victim’s computer or leave a backdoor on their computers. In this paper, a detection model of malicious PowerShell scripts based on hybrid features is proposed, we analyzed the differences between malicious and benign samples in text characters, functions, tokens and the nodes of the abstract syntax tree. Firstly, the script of PowerShell is embedded by FastText. Then the textual features, token features and the nodes features of PowerShell code extracted from the abstract syntax tree are added. Finally, the hybrid features of scrips will be classified by a Random Forest classifier. In the experiment, the malicious scripts are inserted into the benign scripts to weaken the features of the malicious samples in the level of abstract syntax tree nodes and tokens, which makes the scripts more complex. Even in such a complex data set, the proposed model which is based on hybrid features still achieves an accuracy of 97.76% in fivefold cross-validation. Moreover, the accuracy of this proposed model on the original scripts is 98.93%, which means that the proposed model has the ability to classify complex scripts.}
}
```

