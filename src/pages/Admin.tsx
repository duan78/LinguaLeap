import React, { useState } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/Tabs';
import { LessonManager } from '../components/admin/LessonManager';
import { FlashcardManager } from '../components/admin/FlashcardManager';
import { Layout } from 'lucide-react';

export function Admin() {
  const [activeTab, setActiveTab] = useState('lessons');

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex items-center gap-3 mb-8">
        <Layout className="h-6 w-6 text-indigo-600" />
        <h1 className="text-2xl font-bold">Admin Dashboard</h1>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="mb-8">
          <TabsTrigger value="lessons">Lessons</TabsTrigger>
          <TabsTrigger value="flashcards">Flashcards</TabsTrigger>
        </TabsList>

        <TabsContent value="lessons">
          <LessonManager />
        </TabsContent>

        <TabsContent value="flashcards">
          <FlashcardManager />
        </TabsContent>
      </Tabs>
    </div>
  );
}

export default Admin;