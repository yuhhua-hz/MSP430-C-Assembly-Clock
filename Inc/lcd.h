#ifndef LCD_H_
#define LCD_H_

void lcdIni(void);
void lcdLPutc(char c);
void lcdClear(void);
void lcdRPutc(char c);
void lcdBat(int b);
void Puntos(int estado);
unsigned int lcda2seg(char c);

#endif /* LCD_H_ */
