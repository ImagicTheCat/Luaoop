#include <iostream>

struct Animal{
  virtual void eat(){ std::cout << "Animal eating." << std::endl; }
};

struct Cat : public Animal{
  virtual void eat(){ std::cout << "Cat eating." << std::endl; }
  void scratch(){ std::cout << "Cat scratching." << std::endl; }
};

extern "C"{

Animal* Animal_new(){ return new Animal(); }
void Animal_eat(Animal* self){ self->eat(); }
void Animal_delete(Animal* self){ delete self; }

Cat* Cat_new(){ return new Cat(); }
void Cat_scratch(Cat* self){ self->scratch(); }
void Cat_delete(Cat* self){ delete self; }
int Cat___mul_number(Cat* self, int a){ return 42*a; }

}
