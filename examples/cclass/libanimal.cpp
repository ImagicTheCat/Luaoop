#include <iostream>

struct Animal{
  virtual void eat(){ std::cout << "Animal eating." << std::endl; }
};

struct Cat : public Animal{
  virtual void eat(){ std::cout << "Cat eating." << std::endl; }
  void scratch(){ std::cout << "Cat scratching." << std::endl; }
};

extern "C"{

Animal* Animal___new(){ return new Animal(); }
void Animal_eat(Animal* self){ self->eat(); }
void Animal___delete(Animal* self){ delete self; }

Cat* Cat___new(){ return new Cat(); }
void Cat_scratch(Cat* self){ self->scratch(); }
void Cat___delete(Cat* self){ delete self; }

}
